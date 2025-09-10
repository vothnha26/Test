package controllers;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import model.Category;
import service.CategoryService;
import service.impl.CategoryServiceImpl;
import util.Constant;

import java.io.File;
import java.io.IOException;
import java.nio.file.Paths;

@WebServlet("/admin/category/edit")
@MultipartConfig
public class CategoryEditController extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final CategoryService cateService = new CategoryServiceImpl();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        try {
            int id = Integer.parseInt(request.getParameter("id"));
            Category category = cateService.get(id);
            if (category != null) {
                request.setAttribute("category", category);
                RequestDispatcher dispatcher = request.getRequestDispatcher("/views/admin/edit-category.jsp");
                dispatcher.forward(request, response);
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/category/list?error=notfound");
            }
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/category/list?error=invalidid");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        request.setCharacterEncoding("UTF-8");

        try {
            int id = Integer.parseInt(request.getParameter("id"));
            String name = request.getParameter("name");

            Category categoryToUpdate = cateService.get(id);
            if (categoryToUpdate == null) {
                response.sendRedirect(request.getContextPath() + "/admin/category/list?error=notfound");
                return;
            }
            
            categoryToUpdate.setCatename(name);

            Part filePart = request.getPart("icon");
            
            if (filePart != null && filePart.getSize() > 0) {
                String fileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();

                String realPath = request.getServletContext().getRealPath("/");

                String oldIconPath = categoryToUpdate.getIcon();
                if (oldIconPath != null && !oldIconPath.isEmpty()) {
                    File oldFile = new File(realPath + oldIconPath);
                    if (oldFile.exists()) {
                        oldFile.delete();
                    }
                }
                
                String newFileName = System.currentTimeMillis() + "_" + fileName;
                
                String uploadDirPath = realPath + Constant.DIR + File.separator + "category";
                
                File uploadDir = new File(uploadDirPath);
                if (!uploadDir.exists()) {
                    uploadDir.mkdirs();
                }
                
                String filePath = uploadDirPath + File.separator + newFileName;
                
                filePart.write(filePath);
                
                categoryToUpdate.setIcon(Constant.DIR + "/category/" + newFileName);
            }

            cateService.edit(categoryToUpdate);
            response.sendRedirect(request.getContextPath() + "/admin/category/list");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/admin/category/list?error=true");
        }
    }
}