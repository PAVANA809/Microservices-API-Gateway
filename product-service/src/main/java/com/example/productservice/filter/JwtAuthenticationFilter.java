package com.example.productservice.filter;

import com.example.productservice.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;

/**
 * JWT Authentication Filter for validating JWT tokens in requests
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    @Autowired
    private JwtUtil jwtUtil;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, 
                                    FilterChain chain) throws ServletException, IOException {
        
        final String requestTokenHeader = request.getHeader("Authorization");
        
        String username = null;
        String jwtToken = null;
        
        // JWT Token is in the form "Bearer token". Remove Bearer word and get only the Token
        if (requestTokenHeader != null && requestTokenHeader.startsWith("Bearer ")) {
            jwtToken = requestTokenHeader.substring(7);
            try {
                username = jwtUtil.extractUsername(jwtToken);
            } catch (Exception e) {
                logger.warn("Unable to get JWT Token or token is invalid: " + e.getMessage());
            }
        } else {
            logger.debug("JWT Token does not begin with Bearer String");
        }
        
        // Once we get the token validate it.
        if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            
            // Validate token
            if (jwtUtil.validateToken(jwtToken)) {
                // Create UserDetails object
                UserDetails userDetails = User.builder()
                        .username(username)
                        .password("") // Password not needed for JWT authentication
                        .authorities(new ArrayList<>())
                        .build();
                
                UsernamePasswordAuthenticationToken usernamePasswordAuthenticationToken = 
                        new UsernamePasswordAuthenticationToken(
                                userDetails, null, userDetails.getAuthorities());
                
                usernamePasswordAuthenticationToken
                        .setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                
                // Set authentication in SecurityContext
                SecurityContextHolder.getContext().setAuthentication(usernamePasswordAuthenticationToken);
            }
        }
        
        chain.doFilter(request, response);
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) throws ServletException {
        String path = request.getRequestURI();
        
        // Skip JWT validation for public endpoints
        return path.equals("/actuator/health") || 
               path.equals("/actuator/info") ||
               path.startsWith("/actuator/") ||
               path.equals("/api/products"); // Allow public access to product listings
    }
}
