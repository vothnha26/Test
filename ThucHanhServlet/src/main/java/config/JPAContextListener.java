package config;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

@WebListener
public class JPAContextListener implements ServletContextListener {
    
    @Override
    public void contextInitialized(ServletContextEvent sce) {
        try {
            // Initialize JPA
            JPAConfig.init();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        try {
            // Shutdown JPA
            JPAConfig.shutdown();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
