package service.impl;

import java.util.List;

import config.JPAConfig;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import model.Category;
import service.CategoryDao;

public class CategoryDaoImpl implements CategoryDao {
    private EntityManager em;

    public CategoryDaoImpl() {
        em = JPAConfig.getEntityManager();
    }

    public CategoryDaoImpl(EntityManager em) {
        this.em = em;
    }

    @Override
    public void insert(Category category) {
        try {
            em.persist(category);
        } catch (Exception e) {
            throw new RuntimeException("Error inserting category", e);
        }
    }

    @Override
    public void edit(Category category) {
        try {
            Category existingCategory = em.find(Category.class, category.getCateid());
            if (existingCategory != null) {
                existingCategory.setCatename(category.getCatename());
                existingCategory.setIcon(category.getIcon());
                existingCategory.setUserId(category.getUserId());
                em.merge(existingCategory);
            }
        } catch (Exception e) {
            throw new RuntimeException("Error updating category", e);
        }
    }

    @Override
    public void delete(int id) {
        try {
            Category category = em.find(Category.class, id);
            if (category != null) {
                em.remove(category);
            }
        } catch (Exception e) {
            throw new RuntimeException("Error deleting category", e);
        }
    }

    @Override
    public Category get(int id) {
        try {
            return em.find(Category.class, id);
        } catch (Exception e) {
            throw new RuntimeException("Error finding category by id", e);
        }
    }

    @Override
    public Category get(String name) {
        try {
            TypedQuery<Category> query = em.createQuery(
                "SELECT c FROM Category c WHERE c.catename = :name", Category.class);
            query.setParameter("name", name);
            List<Category> results = query.getResultList();
            return results.isEmpty() ? null : results.get(0);
        } catch (Exception e) {
            throw new RuntimeException("Error finding category by name", e);
        }
    }

    @Override
    public List<Category> getAll() {
        try {
            TypedQuery<Category> query = em.createQuery("SELECT c FROM Category c", Category.class);
            return query.getResultList();
        } catch (Exception e) {
            throw new RuntimeException("Error getting all categories", e);
        }
    }

    @Override
    public List<Category> search(String keyword) {
        try {
            TypedQuery<Category> query = em.createQuery(
                "SELECT c FROM Category c WHERE c.catename LIKE :keyword", Category.class);
            query.setParameter("keyword", "%" + keyword + "%");
            return query.getResultList();
        } catch (Exception e) {
            throw new RuntimeException("Error searching categories", e);
        }
    }
    
    public void close() {
        if (em != null && em.isOpen()) {
            em.close();
        }
    }
}
