package com.smartnutri.controller;

import com.smartnutri.dto.FirebaseSyncRequest;
import com.smartnutri.model.User;
import com.smartnutri.repository.UserRepository;
import com.smartnutri.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserRepository userRepository;
    private final UserService userService;

    public AuthController(UserRepository userRepository, UserService userService) {
        this.userRepository = userRepository;
        this.userService = userService;
    }

    @PostMapping("/sync")
    public ResponseEntity<User> syncFirebaseUser(@RequestBody FirebaseSyncRequest request) {
        if (request.getEmail() == null || request.getEmail().isBlank()) {
            return ResponseEntity.badRequest().build();
        }

        // 1. Try finding by firebaseUid first
        Optional<User> byUid = request.getFirebaseUid() != null ?
                userRepository.findByFirebaseUid(request.getFirebaseUid()) : Optional.empty();

        if (byUid.isPresent()) {
            User existing = byUid.get();
            if (request.getFullName() != null && !request.getFullName().isBlank()) {
                existing.setFullName(request.getFullName());
                userRepository.save(existing);
            }
            return ResponseEntity.ok(existing);
        }

        // 2. Try finding by email
        Optional<User> byEmail = userRepository.findByEmail(request.getEmail().trim().toLowerCase());
        if (byEmail.isPresent()) {
            User existing = byEmail.get();
            if (request.getFirebaseUid() != null) {
                existing.setFirebaseUid(request.getFirebaseUid());
            }
            if (request.getFullName() != null && !request.getFullName().isBlank()) {
                existing.setFullName(request.getFullName());
            }
            return ResponseEntity.ok(userRepository.save(existing));
        }

        // 3. Create new student user
        User newUser = User.builder()
                .email(request.getEmail().trim().toLowerCase())
                .firebaseUid(request.getFirebaseUid())
                .fullName(request.getFullName() != null && !request.getFullName().isBlank()
                        ? request.getFullName() : "Sinh viên SmartNutri")
                .height(170.0)
                .weight(62.0)
                .targetWeight(65.0)
                .goalType(User.GoalType.BULK)
                .activityLevel("MODERATE")
                .weeklyBudget(450000.0)
                .build();

        userService.calculateAndSetTargets(newUser);
        User saved = userRepository.save(newUser);
        return ResponseEntity.ok(saved);
    }
}
