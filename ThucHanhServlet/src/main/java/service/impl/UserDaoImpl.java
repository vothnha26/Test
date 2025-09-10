package service.impl;

import config.JPAConfig;
import jakarta.persistence.EntityManager;
import jakarta.persistence.NoResultException;
import jakarta.persistence.TypedQuery;
import model.User;
import model.ResetPasswordStatus;
import service.UserDao;

public class UserDaoImpl implements UserDao {
    private EntityManager em;

    public UserDaoImpl() {
        this.em = JPAConfig.getEntityManager();
    }

    public UserDaoImpl(EntityManager em) {
        this.em = em;
    }
    @Override
    public User get(String username) {
        try {
            TypedQuery<User> query = em.createQuery(
                "SELECT u FROM User u WHERE u.userName = :username", User.class);
            query.setParameter("username", username);
            return query.getSingleResult();
        } catch (NoResultException e) {
            return null;
        } catch (Exception e) {
            throw new RuntimeException("Error finding user: " + e.getMessage(), e);
        }
    }

    @Override
    public void insert(User user) {
        try {
            em.persist(user);
        } catch (Exception e) {
            throw new RuntimeException("Error creating user: " + e.getMessage(), e);
        }
    }

    @Override
    public boolean checkExistEmail(String email) {
        try {
            TypedQuery<Long> query = em.createQuery(
                "SELECT COUNT(u) FROM User u WHERE u.email = :email", Long.class);
            query.setParameter("email", email);
            return query.getSingleResult() > 0;
        } catch (Exception e) {
            throw new RuntimeException("Error checking email: " + e.getMessage(), e);
        }
    }

    @Override
    public boolean checkExistUsername(String username) {
        try {
            TypedQuery<Long> query = em.createQuery(
                "SELECT COUNT(u) FROM User u WHERE u.userName = :username", Long.class);
            query.setParameter("username", username);
            return query.getSingleResult() > 0;
        } catch (Exception e) {
            throw new RuntimeException("Error checking username: " + e.getMessage(), e);
        }
    }

    @Override
    public boolean checkExistPhone(String phone) {
        try {
            TypedQuery<Long> query = em.createQuery(
                "SELECT COUNT(u) FROM User u WHERE u.phone = :phone", Long.class);
            query.setParameter("phone", phone);
            return query.getSingleResult() > 0;
        } catch (Exception e) {
            throw new RuntimeException("Error checking phone: " + e.getMessage(), e);
        }
    }

    @Override
    public ResetPasswordStatus resetPassword(String username, String email, String newPassword, String confirmPassword) {
        if (!newPassword.equals(confirmPassword)) {
            return ResetPasswordStatus.PASSWORD_MISMATCH;
        }

        try {
            TypedQuery<User> query = em.createQuery(
                "SELECT u FROM User u WHERE u.userName = :username", User.class);
            query.setParameter("username", username);
            
            try {
                User user = query.getSingleResult();
                if (!email.equals(user.getEmail())) {
                    return ResetPasswordStatus.EMAIL_MISMATCH;
                }
                user.setPassWord(newPassword);
                em.merge(user);
                return ResetPasswordStatus.SUCCESS;
            } catch (NoResultException e) {
                return ResetPasswordStatus.USER_NOT_FOUND;
            }
        } catch (Exception e) {
            JPAConfig.rollbackTransaction();
            throw new RuntimeException("Error resetting password: " + e.getMessage(), e);
        } finally {
            JPAConfig.closeEntityManager();
        }
    }
}
