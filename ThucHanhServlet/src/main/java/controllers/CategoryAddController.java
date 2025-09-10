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

@MultipartConfig 
@WebServlet({"/admin/category/add"})
public class CategoryAddController extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final CategoryService cateService = new CategoryServiceImpl();

    /**
     * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        RequestDispatcher dispatcher = request.getRequestDispatcher("/views/admin/add-category.jsp");
        dispatcher.forward(request, response);
    }

    /**
     * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        Category category = new Category();

        try {
            String cateName = request.getParameter("name");
            
            if (cateName == null || cateName.trim().isEmpty()) {
                request.setAttribute("error", "Tên danh mục không được để trống!");
                doGet(request, response);
                return;
            }
            category.setCatename(cateName.trim());

            Part filePart = request.getPart("icon");

            if (filePart != null && filePart.getSize() > 0) {
                String fileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
                
                String realPath = request.getServletContext().getRealPath("/");
                String uploadPath = realPath + Constant.DIR;
                
                File uploadDir = new File(uploadPath);
                if (!uploadDir.exists()) {
                    uploadDir.mkdirs();
                }

                String uniqueFileName = System.currentTimeMillis() + "_" + fileName;
                String filePath = uploadPath + File.separator + uniqueFileName;
                
                filePart.write(filePath);
                
                category.setIcon(Constant.DIR + "/" + uniqueFileName);
            }

            cateService.insert(category);
            
            response.sendRedirect(request.getContextPath() + "/admin/category/list");

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Đã có lỗi xảy ra trong quá trình xử lý!");
            doGet(request, response);
        }
    }
}