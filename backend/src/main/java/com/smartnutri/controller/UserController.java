package com.smartnutri.controller;

import com.smartnutri.model.User;
import com.smartnutri.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/profile")
    public ResponseEntity<User> getProfile(@RequestParam(defaultValue = "1") Long userId) {
        return ResponseEntity.ok(userService.getUserProfile(userId));
    }

    @PutMapping("/profile")
    public ResponseEntity<User> updateProfile(@RequestParam(defaultValue = "1") Long userId,
                                              @RequestBody User user) {
        return ResponseEntity.ok(userService.updateProfile(userId, user));
    }
}
