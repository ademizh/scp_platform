// "use client";

// import { useState, useEffect } from "react";
// import RegisterPage from "./register/page";
// import LoginPage from "./login/page";
// import CatalogPage from "./catalog/page";

// export default function Home() {
//   // State to manage which page to show
//   const [user, setUser] = useState(null); // ADDED FOR APP PAGE CONTROL
//   const [currentPage, setCurrentPage] = useState("register"); // ADDED FOR APP PAGE CONTROL

//   // Load user from localStorage on first render
//   useEffect(() => {
//     const storedUser = localStorage.getItem("scp_user");
//     if (storedUser) {
//       setUser(JSON.parse(storedUser));
//       // setCurrentPage("catalog"); // ADDED FOR APP PAGE CONTROL
//     }
//   }, []);

//   // Function to handle navigation between pages
//   const navigateTo = (page) => {
//     setCurrentPage(page); // ADDED FOR APP PAGE CONTROL
//   };

//   // Conditional rendering
//   if (user && currentPage === "catalog") {
//     return <CatalogPage user={user} />; // ADDED FOR APP PAGE CONTROL
//   } else if (currentPage === "login") {
//     return <LoginPage onRegisterClick={() => navigateTo("register")} setUser={setUser} />; // ADDED FOR APP PAGE CONTROL
//   } else {
//     return <RegisterPage onLoginClick={() => navigateTo("login")} setUser={setUser} />; // ADDED FOR APP PAGE CONTROL
//   }
// }