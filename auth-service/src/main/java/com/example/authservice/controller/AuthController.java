package com.example.authservice.controller;

import com.example.authservice.dto.JwtResponse;
import com.example.authservice.dto.LoginRequest;
import com.example.authservice.dto.SignupRequest;
import com.example.authservice.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for authentication operations.
 * Provides endpoints for user signup, login, and token validation.
 */
@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*", maxAge = 3600)
public class AuthController {
    
    @Autowired
    private AuthService authService;

    /**
     * Registers a new user in the system.
     * @param signupRequest the user registration details
     * @return ResponseEntity with success or error message
     */
    @PostMapping("/signup")
    public ResponseEntity<?> registerUser(@Valid @RequestBody SignupRequest signupRequest) {
        String result = authService.registerUser(signupRequest);
        
        if (result.startsWith("Error:")) {
            return ResponseEntity.badRequest().body(result);
        }
        
        return ResponseEntity.ok(result);
    }

    /**
     * Authenticates a user and returns a JWT token.
     * @param loginRequest the user login credentials
     * @return ResponseEntity with JWT token and user details or error message
     */
    @PostMapping("/login")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest) {
        JwtResponse jwtResponse = authService.authenticateUser(loginRequest);
        
        if (jwtResponse != null) {
            return ResponseEntity.ok(jwtResponse);
        }
        
        return ResponseEntity.badRequest().body("Error: Invalid username or password!");
    }

    /**
     * Validates a JWT token and returns user information.
     * @param token the JWT token to validate (from Authorization header)
     * @return ResponseEntity with validation result
     */
    @GetMapping("/validate")
    public ResponseEntity<?> validateToken(@RequestHeader("Authorization") String token) {
        if (token.startsWith("Bearer ")) {
            token = token.substring(7);
        }
        
        String username = authService.validateToken(token);
        
        if (username != null) {
            return ResponseEntity.ok().body("Token is valid for user: " + username);
        }
        
        return ResponseEntity.badRequest().body("Invalid token");
    }

    /**
     * Health check endpoint.
     * @return ResponseEntity with service status
     */
    @GetMapping("/health")
    public ResponseEntity<?> healthCheck() {
        return ResponseEntity.ok("Auth Service is running!");
    }

    /**
     * Load test endpoint - returns the port of this instance
     * @return ResponseEntity with the port number
     */
    @GetMapping("/loadtest")
    public ResponseEntity<String> loadTest(@org.springframework.beans.factory.annotation.Value("${local.server.port}") int port) {
        return ResponseEntity.ok("PORT: " + port);
    }
}
