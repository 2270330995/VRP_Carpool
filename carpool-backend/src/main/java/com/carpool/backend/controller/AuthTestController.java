package com.carpool.backend.controller;

import com.google.firebase.auth.FirebaseToken;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.carpool.backend.service.FirebaseAuthService;

@RestController
@RequestMapping("/api")
public class AuthTestController {

    private final FirebaseAuthService authService;

    public AuthTestController(FirebaseAuthService authService) {
        this.authService = authService;
    }

    @GetMapping("/me")
    public ResponseEntity<?> me(@RequestHeader("Authorization") String authorization) throws Exception {
        String token = authorization.replace("Bearer ", "").trim();
        FirebaseToken decoded = authService.verifyIdToken(token);

        // decoded.getUid() 是用户唯一ID
        return ResponseEntity.ok(
                java.util.Map.of("uid", decoded.getUid(), "email", decoded.getEmail())
        );
    }
}
