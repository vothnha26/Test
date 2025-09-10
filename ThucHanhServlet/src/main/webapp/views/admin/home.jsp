<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <jsp:include page="/common/header.jsp" />
    <title>Admin Dashboard</title>
</head>
<body>
    <div class="d-flex" id="wrapper">
        <jsp:include page="/common/left.jsp" />
        <div id="page-content-wrapper">
            <jsp:include page="/common/topbar.jsp" />
            <div class="container-fluid">
                <h1 class="mt-4">Trang Quản Trị</h1>
                <p>Chào mừng bạn đến với trang quản trị. Hãy chọn một chức năng ở thanh bên trái.</p>
            </div>
        </div>
    </div>
    <jsp:include page="/common/footer.jsp" />
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>