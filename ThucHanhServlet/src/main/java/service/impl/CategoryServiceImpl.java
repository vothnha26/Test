package service.impl;

import java.io.File;
import java.util.List;

import jakarta.persistence.EntityManager;

import config.JPAConfig;
import model.Category; 
import service.CategoryService;

public class CategoryServiceImpl implements CategoryService {
    private final CategoryDaoImpl categoryDao;
    private final EntityManager em;

    public CategoryServiceImpl() {
        this.em = JPAConfig.getEntityManager();
        this.categoryDao = new CategoryDaoImpl(em);
    }

    @Override
    public void insert(Category category) {
        try {
            em.getTransaction().begin();
            categoryDao.insert(category);
            em.getTransaction().commit();
        } catch (Exception e) {
            em.getTransaction().rollback();
            throw e;
        }
    }

    @Override 
    public void edit(Category newCategory) {
        try {
            em.getTransaction().begin();
            
            Category oldCate = categoryDao.get(newCategory.getCateid());
            if (oldCate != null) {
                oldCate.setCatename(newCategory.getCatename());
                
                if (newCategory.getIcon() != null) {
                    // Delete old image if exists
                    String fileName = oldCate.getIcon();
                    if (fileName != null && !fileName.isEmpty()) {
                        String uploadDir = System.getProperty("upload.dir", "uploads");
                        File file = new File(uploadDir + File.separator + "category" + File.separator + fileName);
                        if (file.exists()) {
                            file.delete();
                        }
                    }
                    oldCate.setIcon(newCategory.getIcon());
                }
                
                categoryDao.edit(oldCate);
            }
            
            em.getTransaction().commit();
        } catch (Exception e) {
            em.getTransaction().rollback();
            throw e;
        }
    }

	@Override
	public void delete(int id) {
        try {
            em.getTransaction().begin();
            categoryDao.delete(id);
            em.getTransaction().commit();
        } catch (Exception e) {
            em.getTransaction().rollback();
            throw e;
        }
	}

	@Override
	public Category get(int id) {
		return categoryDao.get(id);
	}

	@Override
	public Category get(String name) {
		return categoryDao.get(name);
	}

	@Override
	public List<Category> getAll() {
		return categoryDao.getAll();
	}

	@Override
	public List<Category> search(String keyword) {
		return categoryDao.search(keyword);
	}
    
    // Clean up resources when service is no longer needed
    public void close() {
        if (em != null) {
            em.close();
        }
    }
}
