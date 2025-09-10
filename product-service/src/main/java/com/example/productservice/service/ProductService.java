package com.example.productservice.service;

import com.example.productservice.dto.CreateProductDto;
import com.example.productservice.model.Product;
import com.example.productservice.repository.ProductRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Service class for Product operations
 * Provides business logic for product management
 */
@Service
@Transactional
public class ProductService {

    private final ProductRepository productRepository;

    public ProductService(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    /**
     * Create a new product
     * @param createProductDto the product creation data
     * @return the created product
     * @throws IllegalArgumentException if SKU already exists
     */
    public Product createProduct(CreateProductDto createProductDto) {
        // Check if SKU already exists
        if (productRepository.existsBySku(createProductDto.getSku())) {
            throw new IllegalArgumentException("Product with SKU '" + createProductDto.getSku() + "' already exists");
        }

        Product product = new Product();
        product.setName(createProductDto.getName());
        product.setDescription(createProductDto.getDescription());
        product.setPrice(createProductDto.getPrice());
        product.setCategory(createProductDto.getCategory());
        product.setSku(createProductDto.getSku());
        product.setStockQuantity(createProductDto.getStockQuantity());
        product.setImageUrl(createProductDto.getImageUrl());
        product.setBrand(createProductDto.getBrand());
        product.setWeight(createProductDto.getWeight());
        product.setDimensions(createProductDto.getDimensions());
        product.setCreatedAt(LocalDateTime.now());
        product.setUpdatedAt(LocalDateTime.now());

        return productRepository.save(product);
    }

    /**
     * Get all products
     * @return list of all products
     */
    @Transactional(readOnly = true)
    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }

    /**
     * Get all products with pagination
     * @param pageable pagination information
     * @return page of products
     */
    @Transactional(readOnly = true)
    public Page<Product> getAllProducts(Pageable pageable) {
        return productRepository.findAll(pageable);
    }

    /**
     * Get product by ID
     * @param id the product ID
     * @return the product if found
     * @throws RuntimeException if product not found
     */
    @Transactional(readOnly = true)
    public Product getProductById(Long id) {
        return productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found with id: " + id));
    }

    /**
     * Get product by SKU
     * @param sku the product SKU
     * @return the product if found
     * @throws RuntimeException if product not found
     */
    @Transactional(readOnly = true)
    public Product getProductBySku(String sku) {
        return productRepository.findBySku(sku)
                .orElseThrow(() -> new RuntimeException("Product not found with SKU: " + sku));
    }

    /**
     * Update an existing product
     * @param id the product ID to update
     * @param createProductDto the updated product data
     * @return the updated product
     * @throws RuntimeException if product not found
     */
    public Product updateProduct(Long id, CreateProductDto createProductDto) {
        Product existingProduct = getProductById(id);

        // Check if SKU is being changed and if new SKU already exists
        if (!existingProduct.getSku().equals(createProductDto.getSku()) && 
            productRepository.existsBySku(createProductDto.getSku())) {
            throw new IllegalArgumentException("Product with SKU '" + createProductDto.getSku() + "' already exists");
        }

        existingProduct.setName(createProductDto.getName());
        existingProduct.setDescription(createProductDto.getDescription());
        existingProduct.setPrice(createProductDto.getPrice());
        existingProduct.setCategory(createProductDto.getCategory());
        existingProduct.setSku(createProductDto.getSku());
        existingProduct.setStockQuantity(createProductDto.getStockQuantity());
        existingProduct.setImageUrl(createProductDto.getImageUrl());
        existingProduct.setBrand(createProductDto.getBrand());
        existingProduct.setWeight(createProductDto.getWeight());
        existingProduct.setDimensions(createProductDto.getDimensions());
        existingProduct.setUpdatedAt(LocalDateTime.now());

        return productRepository.save(existingProduct);
    }

    /**
     * Delete a product by ID
     * @param id the product ID to delete
     * @throws RuntimeException if product not found
     */
    public void deleteProduct(Long id) {
        Product product = getProductById(id);
        productRepository.delete(product);
    }

    /**
     * Get products by category
     * @param category the product category
     * @return list of products in the category
     */
    @Transactional(readOnly = true)
    public List<Product> getProductsByCategory(String category) {
        return productRepository.findByCategory(category);
    }

    /**
     * Get products by category with pagination
     * @param category the product category
     * @param pageable pagination information
     * @return page of products in the category
     */
    @Transactional(readOnly = true)
    public Page<Product> getProductsByCategory(String category, Pageable pageable) {
        return productRepository.findByCategory(category, pageable);
    }

    /**
     * Search products by name
     * @param name the search term
     * @return list of products matching the search term
     */
    @Transactional(readOnly = true)
    public List<Product> searchProductsByName(String name) {
        return productRepository.findByNameContainingIgnoreCase(name);
    }

    /**
     * Search products by name with pagination
     * @param name the search term
     * @param pageable pagination information
     * @return page of products matching the search term
     */
    @Transactional(readOnly = true)
    public Page<Product> searchProductsByName(String name, Pageable pageable) {
        return productRepository.findByNameContainingIgnoreCase(name, pageable);
    }

    /**
     * Get products by brand
     * @param brand the product brand
     * @return list of products from the brand
     */
    @Transactional(readOnly = true)
    public List<Product> getProductsByBrand(String brand) {
        return productRepository.findByBrand(brand);
    }

    /**
     * Get products within a price range
     * @param minPrice minimum price
     * @param maxPrice maximum price
     * @return list of products within the price range
     */
    @Transactional(readOnly = true)
    public List<Product> getProductsByPriceRange(BigDecimal minPrice, BigDecimal maxPrice) {
        return productRepository.findByPriceRange(minPrice, maxPrice);
    }

    /**
     * Get products with sufficient stock
     * @param stockQuantity minimum stock quantity
     * @return list of products with sufficient stock
     */
    @Transactional(readOnly = true)
    public List<Product> getProductsWithStock(Integer stockQuantity) {
        return productRepository.findByStockQuantityGreaterThan(stockQuantity);
    }

    /**
     * Search products by name or description
     * @param searchTerm the search term
     * @param pageable pagination information
     * @return page of products matching the search
     */
    @Transactional(readOnly = true)
    public Page<Product> searchProducts(String searchTerm, Pageable pageable) {
        return productRepository.searchProducts(searchTerm, pageable);
    }

    /**
     * Update product stock quantity
     * @param id the product ID
     * @param stockQuantity the new stock quantity
     * @return the updated product
     */
    public Product updateStock(Long id, Integer stockQuantity) {
        Product product = getProductById(id);
        product.setStockQuantity(stockQuantity);
        product.setUpdatedAt(LocalDateTime.now());
        return productRepository.save(product);
    }

    /**
     * Check if product exists by ID
     * @param id the product ID
     * @return true if product exists, false otherwise
     */
    @Transactional(readOnly = true)
    public boolean productExists(Long id) {
        return productRepository.existsById(id);
    }

    /**
     * Get count of products by category
     * @param category the product category
     * @return number of products in the category
     */
    @Transactional(readOnly = true)
    public long getProductCountByCategory(String category) {
        return productRepository.countByCategory(category);
    }
}
