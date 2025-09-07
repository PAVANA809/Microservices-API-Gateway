package com.example.authservice.dto;

/**
 * Data Transfer Object for JWT authentication responses.
 * Contains the JWT token and user information returned after successful authentication.
 */
public class JwtResponse {
    private String token;
    private String type = "Bearer";
    private String username;
    private String email;

    // Constructors
    public JwtResponse() {}

    public JwtResponse(String token, String username, String email) {
        this.token = token;
        this.username = username;
        this.email = email;
    }

    // Getters and setters
    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
