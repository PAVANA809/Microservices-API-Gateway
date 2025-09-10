package com.example.productservice.repository;

import com.example.productservice.model.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

/**
 * Repository interface for Product entity
 * Provides CRUD operations and custom queries for product management
 */
@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    /**
     * Find products by category
     * @param category the product category
     * @return list of products in the specified category
     */
    List<Product> findByCategory(String category);

    /**
     * Find products by category with pagination
     * @param category the product category
     * @param pageable pagination information
     * @return page of products in the specified category
     */
    Page<Product> findByCategory(String category, Pageable pageable);

    /**
     * Find products by name containing the search term (case-insensitive)
     * @param name the search term
     * @return list of products matching the search term
     */
    List<Product> findByNameContainingIgnoreCase(String name);

    /**
     * Find products by name containing the search term with pagination
     * @param name the search term
     * @param pageable pagination information
     * @return page of products matching the search term
     */
    Page<Product> findByNameContainingIgnoreCase(String name, Pageable pageable);

    /**
     * Find products by brand
     * @param brand the product brand
     * @return list of products from the specified brand
     */
    List<Product> findByBrand(String brand);

    /**
     * Find products within a price range
     * @param minPrice minimum price
     * @param maxPrice maximum price
     * @return list of products within the price range
     */
    @Query("SELECT p FROM Product p WHERE p.price BETWEEN :minPrice AND :maxPrice")
    List<Product> findByPriceRange(@Param("minPrice") BigDecimal minPrice, @Param("maxPrice") BigDecimal maxPrice);

    /**
     * Find products with stock quantity greater than specified amount
     * @param stockQuantity minimum stock quantity
     * @return list of products with sufficient stock
     */
    List<Product> findByStockQuantityGreaterThan(Integer stockQuantity);

    /**
     * Find product by SKU (Stock Keeping Unit)
     * @param sku the product SKU
     * @return optional product with the specified SKU
     */
    Optional<Product> findBySku(String sku);

    /**
     * Check if a product with the given SKU exists
     * @param sku the product SKU
     * @return true if product exists, false otherwise
     */
    boolean existsBySku(String sku);

    /**
     * Find products by multiple categories
     * @param categories list of categories
     * @return list of products in any of the specified categories
     */
    List<Product> findByCategoryIn(List<String> categories);

    /**
     * Search products by name or description (case-insensitive)
     * @param searchTerm the search term
     * @param pageable pagination information
     * @return page of products matching the search in name or description
     */
    @Query("SELECT p FROM Product p WHERE LOWER(p.name) LIKE LOWER(CONCAT('%', :searchTerm, '%')) " +
           "OR LOWER(p.description) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
    Page<Product> searchProducts(@Param("searchTerm") String searchTerm, Pageable pageable);

    /**
     * Count products by category
     * @param category the product category
     * @return number of products in the category
     */
    long countByCategory(String category);
}
