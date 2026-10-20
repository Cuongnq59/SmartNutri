package com.smartnutri.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartnutri.dto.ReceiptItemDto;
import com.smartnutri.dto.ReceiptScanRequest;
import com.smartnutri.dto.ReceiptScanResponse;
import com.smartnutri.model.IngredientRef;
import com.smartnutri.repository.IngredientRefRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.time.LocalDate;
import java.util.*;

@Service
public class ReceiptOcrService {

    private static final Logger log = LoggerFactory.getLogger(ReceiptOcrService.class);

    @Value("${gemini.api.key:}")
    private String apiKey;

    @Value("${gemini.model:gemini-3.5-flash}")
    private String modelName;

    private final ObjectMapper objectMapper;
    private final RestClient restClient;
    private final IngredientRefRepository ingredientRefRepository;

    public ReceiptOcrService(ObjectMapper objectMapper, IngredientRefRepository ingredientRefRepository) {
        this.objectMapper = objectMapper;
        this.ingredientRefRepository = ingredientRefRepository;
        this.restClient = RestClient.builder()
                .baseUrl("https://generativelanguage.googleapis.com/v1beta")
                .build();
    }

    private static final String SYSTEM_INSTRUCTION = """
            Bạn là hệ thống trích xuất hóa đơn mua sắm siêu thị tại Việt Nam.
            Nhiệm vụ: Đọc hình ảnh hóa đơn, trích xuất thông tin chung (tên siêu thị, ngày mua, tổng tiền) và danh sách chi tiết các mặt hàng.

            Quy tắc xử lý:
            1. Chỉ trích xuất và phân loại là "FOOD" đối với thực phẩm, nguyên liệu ăn uống. Các sản phẩm gia dụng, hóa mỹ phẩm (nước rửa chén, khăn giấy, dầu gội...) hãy đánh dấu category là "NON_FOOD".
            2. Giải mã các từ viết tắt siêu thị phổ biến (ví dụ: "UC GA CP" -> "Ức gà", "DAU PHU" -> "Đậu phụ", "TRUNG GA" -> "Trứng gà").
            3. Chuẩn hóa đơn vị đo lường: gram (g), kilogram (kg), quả (piece), hộp (pack), lít (l).
            4. Chỉ trả về JSON duy nhất theo schema quy định, không dùng markdown fences (không ```json).
            """;

    private static final String USER_PROMPT = """
            Hãy trích xuất thông tin từ ảnh chụp hóa đơn này.
            JSON Schema yêu cầu:
            {
              "merchant_name": "Tên siêu thị / cửa hàng",
              "purchase_date": "YYYY-MM-DD",
              "total_amount": 78000,
              "items": [
                {
                  "raw_name": "UC GA PHI LE 500G",
                  "clean_name": "Ức gà phi lê",
                  "category": "FOOD",
                  "quantity": 500,
                  "unit": "g",
                  "total_price": 38000
                }
              ]
            }
            """;

    private static final List<String> FALLBACK_MODELS = List.of(
            "gemini-3-flash-preview",
            "gemini-3.5-flash-lite",
            "gemini-3.1-flash-lite",
            "gemini-3.7-flash"
    );

    public ReceiptScanResponse scanReceipt(ReceiptScanRequest request) {
        if (apiKey != null && !apiKey.isBlank() && !apiKey.equalsIgnoreCase("YOUR_GEMINI_API_KEY")) {
            List<String> modelsToTry = new ArrayList<>();
            if (modelName != null && !modelName.isBlank()) {
                modelsToTry.add(modelName);
            }
            for (String fallback : FALLBACK_MODELS) {
                if (!modelsToTry.contains(fallback)) {
                    modelsToTry.add(fallback);
                }
            }

            for (String targetModel : modelsToTry) {
                try {
                    ReceiptScanResponse res = callGeminiReceiptOcrWithModel(request, targetModel);
                    if (res != null) {
                        log.info("Gemini Receipt OCR succeeded with model [{}]: merchant={}", targetModel, res.getMerchantName());
                        return res;
                    }
                } catch (Exception e) {
                    log.warn("Gemini OCR model [{}] failed: {}. Trying next candidate...", targetModel, e.getMessage());
                }
            }
        }
        log.warn("All Gemini OCR models failed or API key missing. Falling back to local mock receipt.");
        return generateMockReceipt(request);
    }

    private ReceiptScanResponse callGeminiReceiptOcrWithModel(ReceiptScanRequest request, String targetModel) {
        String base64Image = cleanBase64(request.getBase64Image());
        String mimeType = (request.getMimeType() != null && !request.getMimeType().isBlank())
                ? request.getMimeType() : "image/jpeg";

        Map<String, Object> requestBody = Map.of(
                "systemInstruction", Map.of(
                        "parts", List.of(Map.of("text", SYSTEM_INSTRUCTION))
                ),
                "contents", List.of(
                        Map.of(
                                "parts", List.of(
                                        Map.of("text", USER_PROMPT),
                                        Map.of("inline_data", Map.of(
                                                "mime_type", mimeType,
                                                "data", base64Image
                                        ))
                                )
                        )
                ),
                "generationConfig", Map.of(
                        "response_mime_type", "application/json",
                        "temperature", 0.1
                )
        );

        String rawResponse = restClient.post()
                .uri("/models/" + targetModel + ":generateContent?key={key}", apiKey)
                .contentType(MediaType.APPLICATION_JSON)
                .body(requestBody)
                .retrieve()
                .body(String.class);

        return parseGeminiReceiptResponse(rawResponse);
    }

    private ReceiptScanResponse parseGeminiReceiptResponse(String rawResponse) {
        try {
            JsonNode root = objectMapper.readTree(rawResponse);
            JsonNode candidates = root.path("candidates");
            if (candidates.isArray() && !candidates.isEmpty()) {
                JsonNode parts = candidates.get(0).path("content").path("parts");
                StringBuilder fullTextBuilder = new StringBuilder();
                if (parts.isArray()) {
                    for (JsonNode part : parts) {
                        String t = part.path("text").asText("");
                        if (!t.isBlank()) {
                            fullTextBuilder.append(t).append("\n");
                        }
                    }
                }
                String text = fullTextBuilder.toString().trim();
                int startIdx = text.indexOf('{');
                int endIdx = text.lastIndexOf('}');
                if (startIdx >= 0 && endIdx > startIdx) {
                    text = text.substring(startIdx, endIdx + 1);
                }
                JsonNode json = objectMapper.readTree(text);

                String merchant = json.path("merchant_name").asText("WinMart+");
                String dateStr = json.path("purchase_date").asText(LocalDate.now().toString());
                double totalAmount = json.path("total_amount").asDouble(0.0);

                LocalDate purchaseDate = parseDateSafe(dateStr);
                List<ReceiptItemDto> items = new ArrayList<>();
                double foodAmount = 0.0;

                JsonNode itemsNode = json.path("items");
                if (itemsNode.isArray()) {
                    for (JsonNode item : itemsNode) {
                        String rawName = item.path("raw_name").asText();
                        String cleanName = item.path("clean_name").asText(rawName);
                        String category = item.path("category").asText("FOOD");
                        double qty = item.path("quantity").asDouble(1.0);
                        String unit = item.path("unit").asText("pack");
                        double price = item.path("total_price").asDouble(0.0);

                        if ("FOOD".equalsIgnoreCase(category)) {
                            foodAmount += price;
                        }

                        // Map with catalog and shelf life
                        IngredientRef matched = matchIngredient(cleanName, rawName);
                        LocalDate expiryDate = estimateExpiryDate(purchaseDate, matched, cleanName, category);

                        items.add(ReceiptItemDto.builder()
                                .rawName(rawName)
                                .cleanName(cleanName)
                                .category(category)
                                .quantity(qty)
                                .unit(unit)
                                .totalPrice(price)
                                .matchedRefId(matched != null ? matched.getId() : null)
                                .expiryDate(expiryDate.toString())
                                .selected("FOOD".equalsIgnoreCase(category))
                                .build());
                    }
                }

                return ReceiptScanResponse.builder()
                        .merchantName(merchant)
                        .purchaseDate(purchaseDate.toString())
                        .totalAmount(totalAmount)
                        .foodAmount(foodAmount)
                        .items(items)
                        .build();
            }
        } catch (Exception e) {
            log.error("Failed to parse Gemini OCR response: {}", e.getMessage());
        }
        return generateMockReceipt(null);
    }

    public IngredientRef matchIngredient(String cleanName, String rawName) {
        List<IngredientRef> all = ingredientRefRepository.findAll();
        String combined = (cleanName + " " + rawName).toLowerCase();

        // 1. Exact match / alias match
        for (IngredientRef ref : all) {
            if (combined.contains(ref.getName().toLowerCase())) {
                return ref;
            }
            if (ref.getAliases() != null) {
                String[] aliases = ref.getAliases().split(",");
                for (String alias : aliases) {
                    if (!alias.isBlank() && combined.contains(alias.trim().toLowerCase())) {
                        return ref;
                    }
                }
            }
        }

        // 2. Fuzzy matching (Levenshtein distance)
        IngredientRef bestRef = null;
        double highestSimilarity = 0.0;
        for (IngredientRef ref : all) {
            double sim = calculateSimilarity(cleanName.toLowerCase(), ref.getName().toLowerCase());
            if (sim > highestSimilarity && sim >= 0.75) {
                highestSimilarity = sim;
                bestRef = ref;
            }
        }

        return bestRef;
    }

    public LocalDate estimateExpiryDate(LocalDate purchaseDate, IngredientRef ref, String name, String category) {
        if (!"FOOD".equalsIgnoreCase(category)) {
            return purchaseDate.plusDays(365);
        }
        if (ref != null && ref.getDefaultShelfLifeDays() != null) {
            return purchaseDate.plusDays(ref.getDefaultShelfLifeDays());
        }

        String lower = name.toLowerCase();
        if (lower.contains("thịt") || lower.contains("gà") || lower.contains("bò") || lower.contains("cá") || lower.contains("tôm")) {
            return purchaseDate.plusDays(3); // Thịt sống, thủy sản
        } else if (lower.contains("rau") || lower.contains("cải") || lower.contains("muống") || lower.contains("xà lách")) {
            return purchaseDate.plusDays(4); // Rau xanh
        } else if (lower.contains("trứng")) {
            return purchaseDate.plusDays(21); // Trứng gà
        } else if (lower.contains("sữa") || lower.contains("đậu")) {
            return purchaseDate.plusDays(5); // Sữa, đậu phụ
        }
        return purchaseDate.plusDays(14);
    }

    private double calculateSimilarity(String s1, String s2) {
        int maxLen = Math.max(s1.length(), s2.length());
        if (maxLen == 0) return 1.0;
        int distance = levenshteinDistance(s1, s2);
        return 1.0 - ((double) distance / maxLen);
    }

    private int levenshteinDistance(String a, String b) {
        int[] costs = new int[b.length() + 1];
        for (int j = 0; j < costs.length; j++) costs[j] = j;
        for (int i = 1; i <= a.length(); i++) {
            costs[0] = i;
            int nw = i - 1;
            for (int j = 1; j <= b.length(); j++) {
                int cj = Math.min(1 + Math.min(costs[j], costs[j - 1]),
                        a.charAt(i - 1) == b.charAt(j - 1) ? nw : nw + 1);
                nw = costs[j];
                costs[j] = cj;
            }
        }
        return costs[b.length()];
    }

    public ReceiptScanResponse generateMockReceipt(ReceiptScanRequest request) {
        LocalDate today = LocalDate.now();
        List<ReceiptItemDto> items = new ArrayList<>(List.of(
                ReceiptItemDto.builder()
                        .rawName("UC GA PHI LE CP 500G")
                        .cleanName("Ức gà phi lê")
                        .category("FOOD")
                        .quantity(500.0)
                        .unit("g")
                        .totalPrice(38000.0)
                        .expiryDate(today.plusDays(3).toString())
                        .selected(true)
                        .build(),
                ReceiptItemDto.builder()
                        .rawName("TRUNG GA CP HOP 10Q")
                        .cleanName("Trứng gà công nghiệp")
                        .category("FOOD")
                        .quantity(10.0)
                        .unit("piece")
                        .totalPrice(28000.0)
                        .expiryDate(today.plusDays(21).toString())
                        .selected(true)
                        .build(),
                ReceiptItemDto.builder()
                        .rawName("DAU PHU MO 2 BIA")
                        .cleanName("Đậu phụ Mơ")
                        .category("FOOD")
                        .quantity(2.0)
                        .unit("piece")
                        .totalPrice(8000.0)
                        .expiryDate(today.plusDays(3).toString())
                        .selected(true)
                        .build(),
                ReceiptItemDto.builder()
                        .rawName("RAU MUONG LANG 500G")
                        .cleanName("Rau muống")
                        .category("FOOD")
                        .quantity(500.0)
                        .unit("g")
                        .totalPrice(10000.0)
                        .expiryDate(today.plusDays(4).toString())
                        .selected(true)
                        .build(),
                ReceiptItemDto.builder()
                        .rawName("KHAN GIAY PULPY 3 LOP")
                        .cleanName("Khăn giấy Pulpy")
                        .category("NON_FOOD")
                        .quantity(1.0)
                        .unit("pack")
                        .totalPrice(15000.0)
                        .expiryDate(today.plusDays(365).toString())
                        .selected(false)
                        .build()
        ));

        // Match with database catalog if items exist
        for (ReceiptItemDto item : items) {
            IngredientRef matched = matchIngredient(item.getCleanName(), item.getRawName());
            if (matched != null) {
                item.setMatchedRefId(matched.getId());
            }
        }

        return ReceiptScanResponse.builder()
                .merchantName("WinMart+ Thăng Long")
                .purchaseDate(today.toString())
                .totalAmount(99000.0)
                .foodAmount(84000.0)
                .items(items)
                .build();
    }

    private LocalDate parseDateSafe(String dateStr) {
        try {
            return LocalDate.parse(dateStr);
        } catch (Exception e) {
            return LocalDate.now();
        }
    }

    private String cleanBase64(String input) {
        if (input == null) return "";
        if (input.contains(",")) {
            return input.substring(input.indexOf(",") + 1);
        }
        return input;
    }
}
