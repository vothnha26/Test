package service.impl;

import jakarta.persistence.EntityManager;

import config.JPAConfig;
import model.User;
import model.ResetPasswordStatus;
import service.UserDao;
import service.UserService;

public class UserServiceImpl implements UserService {
    private final UserDao userDao;
    private final EntityManager em;

    public UserServiceImpl() {
        this.em = JPAConfig.getEntityManager();
        this.userDao = new UserDaoImpl(em);
    }

    @Override
    public User login(String username, String password) {
        User user = this.get(username);
        if (user != null && password.equals(user.getPassWord())) {
            return user;
        }
        return null;
    }

    @Override
    public User get(String username) {
        return userDao.get(username);
    }

    @Override
    public void insert(User user) {
        try {
            em.getTransaction().begin();
            userDao.insert(user);
            em.getTransaction().commit();
        } catch (Exception e) {
            em.getTransaction().rollback();
            throw e;
        }
    }

    @Override
    public boolean register(String username, String password, String email, String fullname, String phone) {
        try {
            if (userDao.checkExistUsername(username)) {
                return false;
            }

            long millis = System.currentTimeMillis();
            java.sql.Date registrationDate = new java.sql.Date(millis);

            User newUser = new User();
            newUser.setEmail(email);
            newUser.setUserName(username);
            newUser.setFullName(fullname);
            newUser.setPassWord(password);
            newUser.setAvatar(null);
            newUser.setRoleid(2); // Set role id to 2 for normal users
            newUser.setPhone(phone);
            newUser.setCreatedDate(registrationDate);

            em.getTransaction().begin();
            userDao.insert(newUser);
            em.getTransaction().commit();

            return true;
        } catch (Exception e) {
            em.getTransaction().rollback();
            throw e;
        }
    }

	
	@Override
    public boolean checkExistUsername(String username) {
        return userDao.checkExistUsername(username);
    }

    @Override
    public boolean checkExistPhone(String phone) {
        return userDao.checkExistPhone(phone);
    }
    
    @Override
    public boolean checkExistEmail(String email) {
        return userDao.checkExistEmail(email);
    }

    @Override
    public ResetPasswordStatus resetPassword(String name, String email, String newPassword, String confirmPassword) {
        try {
            em.getTransaction().begin();
            ResetPasswordStatus status = userDao.resetPassword(name, email, newPassword, confirmPassword);
            em.getTransaction().commit();
            return status;
        } catch (Exception e) {
            em.getTransaction().rollback();
            throw e;
        }
    }
    
    // Clean up resources when service is no longer needed
    public void close() {
        if (em != null) {
            em.close();
        }
    }
}