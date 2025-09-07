package com.example.userservice.service;

import com.example.userservice.dto.CreateUserDto;
import com.example.userservice.dto.UpdateUserDto;
import com.example.userservice.model.User;
import com.example.userservice.repository.UserRepository;
import com.example.userservice.exception.UserNotFoundException;
import com.example.userservice.exception.DuplicateUserException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Service class for User operations
 * Handles business logic for user management including CRUD operations
 */
@Service
@Transactional
public class UserService {

    private final UserRepository userRepository;

    @Autowired
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    /**
     * Create a new user
     * @param createUserDto the user data to create
     * @return the created user
     * @throws DuplicateUserException if username or email already exists
     */
    public User createUser(CreateUserDto createUserDto) {
        // Check if username already exists
        if (userRepository.existsByUsername(createUserDto.getUsername())) {
            throw new DuplicateUserException("Username '" + createUserDto.getUsername() + "' already exists");
        }

        // Check if email already exists
        if (userRepository.existsByEmail(createUserDto.getEmail())) {
            throw new DuplicateUserException("Email '" + createUserDto.getEmail() + "' already exists");
        }

        // Create new user
        User user = new User();
        user.setUsername(createUserDto.getUsername());
        user.setEmail(createUserDto.getEmail());
        user.setFirstName(createUserDto.getFirstName());
        user.setLastName(createUserDto.getLastName());
        user.setPhone(createUserDto.getPhone());
        user.setAddress(createUserDto.getAddress());

        return userRepository.save(user);
    }

    /**
     * Get user by ID
     * @param id the user ID
     * @return the user
     * @throws UserNotFoundException if user not found
     */
    @Transactional(readOnly = true)
    public User getUserById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + id));
    }

    /**
     * Get user by username
     * @param username the username
     * @return the user
     * @throws UserNotFoundException if user not found
     */
    @Transactional(readOnly = true)
    public User getUserByUsername(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new UserNotFoundException("User not found with username: " + username));
    }

    /**
     * Get all users with pagination
     * @param pageable pagination information
     * @return page of users
     */
    @Transactional(readOnly = true)
    public Page<User> getAllUsers(Pageable pageable) {
        return userRepository.findAll(pageable);
    }

    /**
     * Get all active users
     * @return list of active users
     */
    @Transactional(readOnly = true)
    public List<User> getActiveUsers() {
        return userRepository.findByActiveTrue();
    }

    /**
     * Search users by name
     * @param name the name to search for
     * @return list of users matching the name
     */
    @Transactional(readOnly = true)
    public List<User> searchUsersByName(String name) {
        return userRepository.findByNameContaining(name);
    }

    /**
     * Update user
     * @param id the user ID to update
     * @param updateUserDto the update data
     * @return the updated user
     * @throws UserNotFoundException if user not found
     * @throws DuplicateUserException if username or email conflicts with another user
     */
    public User updateUser(Long id, UpdateUserDto updateUserDto) {
        User existingUser = getUserById(id);

        // Check for username conflicts (if username is being updated)
        if (updateUserDto.getUsername() != null && 
            !updateUserDto.getUsername().equals(existingUser.getUsername())) {
            if (userRepository.existsByUsername(updateUserDto.getUsername())) {
                throw new DuplicateUserException("Username '" + updateUserDto.getUsername() + "' already exists");
            }
            existingUser.setUsername(updateUserDto.getUsername());
        }

        // Check for email conflicts (if email is being updated)
        if (updateUserDto.getEmail() != null && 
            !updateUserDto.getEmail().equals(existingUser.getEmail())) {
            if (userRepository.existsByEmail(updateUserDto.getEmail())) {
                throw new DuplicateUserException("Email '" + updateUserDto.getEmail() + "' already exists");
            }
            existingUser.setEmail(updateUserDto.getEmail());
        }

        // Update other fields if provided
        if (updateUserDto.getFirstName() != null) {
            existingUser.setFirstName(updateUserDto.getFirstName());
        }
        if (updateUserDto.getLastName() != null) {
            existingUser.setLastName(updateUserDto.getLastName());
        }
        if (updateUserDto.getPhone() != null) {
            existingUser.setPhone(updateUserDto.getPhone());
        }
        if (updateUserDto.getAddress() != null) {
            existingUser.setAddress(updateUserDto.getAddress());
        }
        if (updateUserDto.getActive() != null) {
            existingUser.setActive(updateUserDto.getActive());
        }

        return userRepository.save(existingUser);
    }

    /**
     * Delete user by ID
     * @param id the user ID to delete
     * @throws UserNotFoundException if user not found
     */
    public void deleteUser(Long id) {
        if (!userRepository.existsById(id)) {
            throw new UserNotFoundException("User not found with ID: " + id);
        }
        userRepository.deleteById(id);
    }

    /**
     * Deactivate user (soft delete)
     * @param id the user ID to deactivate
     * @return the deactivated user
     * @throws UserNotFoundException if user not found
     */
    public User deactivateUser(Long id) {
        User user = getUserById(id);
        user.setActive(false);
        return userRepository.save(user);
    }

    /**
     * Activate user
     * @param id the user ID to activate
     * @return the activated user
     * @throws UserNotFoundException if user not found
     */
    public User activateUser(Long id) {
        User user = getUserById(id);
        user.setActive(true);
        return userRepository.save(user);
    }

    /**
     * Check if user exists by ID
     * @param id the user ID to check
     * @return true if user exists, false otherwise
     */
    @Transactional(readOnly = true)
    public boolean userExists(Long id) {
        return userRepository.existsById(id);
    }

    /**
     * Get total count of users
     * @return total number of users
     */
    @Transactional(readOnly = true)
    public long getTotalUserCount() {
        return userRepository.count();
    }
}
