package com.example.authservice.service;

import com.example.authservice.dto.JwtResponse;
import com.example.authservice.dto.LoginRequest;
import com.example.authservice.dto.SignupRequest;
import com.example.authservice.model.User;
import com.example.authservice.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

/**
 * Service class for user authentication operations including signup, login, and user management.
 * Handles business logic for user registration and authentication.
 */
@Service
public class AuthService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    @Autowired
    private JwtService jwtService;

    /**
     * Registers a new user in the system.
     * @param signupRequest the signup request containing user details
     * @return success message or error message
     */
    public String registerUser(SignupRequest signupRequest) {
        if (userRepository.existsByUsername(signupRequest.getUsername())) {
            return "Error: Username is already taken!";
        }

        if (userRepository.existsByEmail(signupRequest.getEmail())) {
            return "Error: Email is already in use!";
        }

        // Create new user
        User user = new User(
                signupRequest.getUsername(),
                signupRequest.getEmail(),
                passwordEncoder.encode(signupRequest.getPassword())
        );

        userRepository.save(user);
        return "User registered successfully!";
    }

    /**
     * Authenticates a user and generates a JWT token.
     * @param loginRequest the login request containing credentials
     * @return JwtResponse with token and user details, or null if authentication fails
     */
    public JwtResponse authenticateUser(LoginRequest loginRequest) {
        Optional<User> userOptional = userRepository.findByUsername(loginRequest.getUsername());
        
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            
            if (passwordEncoder.matches(loginRequest.getPassword(), user.getPassword())) {
                String jwt = jwtService.generateJwtToken(user.getUsername());
                return new JwtResponse(jwt, user.getUsername(), user.getEmail());
            }
        }
        
        return null; // Authentication failed
    }

    /**
     * Finds a user by username.
     * @param username the username to search for
     * @return Optional containing the user if found
     */
    public Optional<User> findByUsername(String username) {
        return userRepository.findByUsername(username);
    }

    /**
     * Validates if a JWT token is valid and extracts user information.
     * @param token the JWT token to validate
     * @return the username if token is valid, null otherwise
     */
    public String validateToken(String token) {
        if (jwtService.validateJwtToken(token)) {
            return jwtService.getUsernameFromJwtToken(token);
        }
        return null;
    }
}
