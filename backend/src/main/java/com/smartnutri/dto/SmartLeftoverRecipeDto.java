package com.smartnutri.dto;

import lombok.*;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SmartLeftoverRecipeDto {
    private String title;
    private String cookingTime; // e.g. "15 phút"
    private String equipment; // e.g. "Chảo chống dính", "Nồi cơm điện"
    private List<String> ingredientsUsed;
    private Double proteinG;
    private Double calories;
    private List<String> instructions;
}
