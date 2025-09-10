package config;

import java.util.HashMap;
import java.util.Map;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityManagerFactory;
import jakarta.persistence.Persistence;

public class JPAConfig {
    private static EntityManagerFactory factory;
    private static final String PERSISTENCE_UNIT_NAME = "ThucHanhServlet";
    private static final ThreadLocal<EntityManager> threadLocal = new ThreadLocal<>();

    public static void init() {
        try {
            if (factory == null || !factory.isOpen()) {
                ClassLoader contextClassLoader = Thread.currentThread().getContextClassLoader();
                try {
                    Thread.currentThread().setContextClassLoader(JPAConfig.class.getClassLoader());
                    
                    // Create properties map
                    Map<String, String> properties = new HashMap<>();
                    properties.put("hibernate.connection.provider_class", "org.hibernate.hikaricp.internal.HikariCPConnectionProvider");
                    properties.put("hibernate.dialect", "org.hibernate.dialect.SQLServerDialect");
                    
                    factory = Persistence.createEntityManagerFactory(PERSISTENCE_UNIT_NAME, properties);
                    
                    if (factory == null) {
                        throw new RuntimeException("EntityManagerFactory could not be created");
                    }
                } finally {
                    Thread.currentThread().setContextClassLoader(contextClassLoader);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            throw new RuntimeException("Could not initialize JPA EntityManagerFactory: " + e.getMessage() +
                    "\nMake sure persistence.xml is properly configured and all required JARs are in the classpath", e);
        }
    }

    public static EntityManager getEntityManager() {
        init();
        EntityManager em = threadLocal.get();
        
        if (em == null || !em.isOpen()) {
            em = factory.createEntityManager();
            threadLocal.set(em);
        }
        return em;
    }

    public static void closeEntityManager() {
        EntityManager em = threadLocal.get();
        if (em != null && em.isOpen()) {
            em.close();
            threadLocal.remove();
        }
    }

    public static void beginTransaction() {
        getEntityManager().getTransaction().begin();
    }

    public static void commitTransaction() {
        EntityManager em = getEntityManager();
        if (em.getTransaction().isActive()) {
            em.getTransaction().commit();
        }
    }

    public static void rollbackTransaction() {
        EntityManager em = getEntityManager();
        if (em.getTransaction().isActive()) {
            em.getTransaction().rollback();
        }
    }

    public static void shutdown() {
        closeEntityManager();
        if (factory != null && factory.isOpen()) {
            factory.close();
        }
    }
}
