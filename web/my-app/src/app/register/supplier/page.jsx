"use client";

import React, { useState } from 'react';
import { UserPlus, Loader, Building2, Package } from "lucide-react";

// Base URL of your Django backend – kept for functionality
const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://127.0.0.1:8000';

// Универсальный helper для запросов к Django API
async function apiFetch(path, { method = "GET", body, userId } = {}) {
    const headers = {
        "Content-Type": "application/json",
    };

    if (userId) {
        headers["X-User-Id"] = String(userId); // для RLS в Products / Orders
    }

    const res = await fetch(`${API_BASE_URL}${path}`, {
        method,
        headers,
        body: body ? JSON.stringify(body) : undefined,
    });

    // DELETE / 204 — тела нет
    if (res.status === 204) return null;

    let data;
    try {
        data = await res.json();
    } catch {
        throw new Error("Server returned non-JSON response");
    }

    if (!res.ok) {
        const msg = data.detail || "Server error";
        throw new Error(msg);
    }

    return data;
}

// --- Simple Components with Requested Styling ---

const RegistrationForm = ({ formData, manageChange, manageRegistrationSubmit, loading }) => (
    <form onSubmit={manageRegistrationSubmit} className="space-y-4">
        <h2 className="text-xl font-bold mb-4 text-gray-800">Register Supplier Account</h2>

        {/* Supplier Name */}
        <div>
            <label htmlFor="supplierName" className="block text-sm font-medium mb-1 text-gray-700">Supplier/Company Name</label>
            <div className="flex items-center border border-gray-400 p-2">
                <Building2 className="h-4 w-4 text-gray-500 mr-2" />
                <input
                    id="supplierName"
                    type="text"
                    className="w-full outline-none text-gray-900"
                    onChange={manageChange}
                    value={formData.supplierName}
                    placeholder="Company Name"
                    required
                />
            </div>
        </div>

        {/* Email */}
        <div>
            <label htmlFor="email" className="block text-sm font-medium mb-1 text-gray-700">Business Email</label>
            <input
                id="email"
                type="email"
                className="w-full border border-gray-400 p-2 text-gray-900"
                onChange={manageChange}
                value={formData.email}
                placeholder="email@example.com"
                required
            />
        </div>

        {/* Password */}
        <div>
            <label htmlFor="password" className="block text-sm font-medium mb-1 text-gray-700">Password</label>
            <input
                id="password"
                type="password"
                className="w-full border border-gray-400 p-2 text-gray-900"
                onChange={manageChange}
                value={formData.password}
                placeholder="••••••••"
                required
            />
        </div>

        {/* Confirm Password */}
        <div>
            <label htmlFor="confirmPassword" className="block text-sm font-medium mb-1 text-gray-700">Confirm Password</label>
            <input
                id="confirmPassword"
                type="password"
                className="w-full border border-gray-400 p-2 text-gray-900"
                onChange={manageChange}
                value={formData.confirmPassword}
                placeholder="••••••••"
                required
            />
        </div>

        {/* Submit Button */}
        <button
            type="submit"
            className="w-full bg-gray-700 text-white py-2 mt-4 flex items-center justify-center hover:bg-gray-600 transition duration-150"
            disabled={loading}
        >
            {loading ? (
                <><Loader className="h-4 w-4 mr-2 animate-spin" /> Processing...</>
            ) : (
                <><UserPlus className="h-4 w-4 mr-2" /> Register Supplier Account</>
            )}
        </button>
    </form>
);


const LoginForm = ({ formData, manageChange, manageLoginSubmit, loading }) => (
    <form onSubmit={manageLoginSubmit} className="space-y-4">
        <h2 className="text-xl font-bold mb-4 text-gray-800">Supplier Login</h2>

        {/* Email Field */}
        <div>
            <label htmlFor="email" className="block text-sm font-medium mb-1 text-gray-700">Email Address</label>
            <input
                type="email"
                id="email"
                value={formData.email}
                onChange={manageChange}
                className="w-full border border-gray-400 p-2 text-gray-900"
                placeholder="email@company.com"
                required
            />
        </div>

        {/* Password Field */}
        <div>
            <label htmlFor="password" className="block text-sm font-medium mb-1 text-gray-700">Password</label>
            <input
                type="password"
                id="password"
                value={formData.password}
                onChange={manageChange}
                className="w-full border border-gray-400 p-2 text-gray-900"
                placeholder="Enter password"
                required
            />
        </div>

        {/* Submit Button */}
        <button
            type="submit"
            className="w-full bg-gray-700 text-white py-2 mt-4 flex items-center justify-center hover:bg-gray-600 transition duration-150"
            disabled={loading}
        >
            {loading ? (
                <><Loader className="h-4 w-4 mr-2 animate-spin" /> Logging in...</>
            ) : (
                "Log In as Supplier"
            )}
        </button>
    </form>
);


const CatalogView = ({
    productForm,
    manageProductUpdate,
    manageAddProduct,
    productList,
    manageProductDelete,
    successMessage,
    editingProductId,
    enterEditMode,

    setView,
    setError,
    setMessage
}) => (
    <div className="p-6 border border-gray-400 bg-white w-full max-w-4xl mx-auto">
        <div className="flex items-center justify-between mb-6 border-b pb-3">
            <h1 className="text-2xl font-bold text-gray-800">📦 Supplier Catalog Dashboard</h1>
            <button
                onClick={() => setView("requests")}
                className="bg-gray-700 text-white px-4 py-2 rounded-lg hover:bg-gray-600 transition"
            >
                View Requests
            </button>

            <button
                onClick={() => { setView("login"); setError(""); setMessage(""); }}
                className="bg-gray-700 text-white px-4 py-2 rounded-lg hover:bg-gray-600 transition duration-200"
            >
                Log Out
            </button>
        </div>


        {successMessage && (
            <div className="bg-green-100 text-green-700 p-3 mb-4 border border-green-500 text-sm">
                {successMessage}
            </div>
        )}

        {/* Add / Update Product Form */}
        <div className="mb-8 p-4 border border-gray-400 bg-gray-50">
            <h2 className="text-lg font-semibold mb-4 text-gray-700">
                {editingProductId ? "Update Product" : "Add Product"}
            </h2>

            <form onSubmit={manageAddProduct} className="space-y-3">

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label htmlFor="productName" className="block text-sm font-medium text-gray-700">Name</label>
                        <input
                            id="productName"
                            type="text"
                            className="w-full border border-gray-400 p-2 text-gray-900"
                            onChange={manageProductUpdate}
                            value={productForm.productName}
                            required
                        />
                    </div>

                    <div>
                        <label htmlFor="price" className="block text-sm font-medium text-gray-700">Price ($)</label>
                        <input
                            id="price"
                            type="number"
                            className="w-full border border-gray-400 p-2 text-gray-900"
                            onChange={manageProductUpdate}
                            value={productForm.price}
                            required
                        />
                    </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label htmlFor="stock" className="block text-sm font-medium text-gray-700">Stock</label>
                        <input
                            id="stock"
                            type="number"
                            className="w-full border border-gray-400 p-2 text-gray-900"
                            onChange={manageProductUpdate}
                            value={productForm.stock}
                            required
                        />
                    </div>

                    <div>
                        <label htmlFor="unit" className="block text-sm font-medium text-gray-700">Unit</label>
                        <input
                            id="unit"
                            type="text"
                            className="w-full border border-gray-400 p-2 text-gray-900"
                            onChange={manageProductUpdate}
                            value={productForm.unit}
                            required
                        />
                    </div>

                    <div>
                        <label htmlFor="discount" className="block text-sm font-medium text-gray-700">Discount (%)</label>
                        <input
                            id="discount"
                            type="number"
                            className="w-full border border-gray-400 p-2 text-gray-900"
                            onChange={manageProductUpdate}
                            value={productForm.discount}
                        />
                    </div>
                </div>

                {/* Submit Button */}
                <button
                    type="submit"
                    className="w-full bg-gray-700 text-white py-2 hover:bg-gray-600 transition duration-150"
                >
                    <Package className="h-4 w-4 mr-2 inline" />{" "}
                    {editingProductId ? "Update Product" : "Add Product"}
                </button>
            </form>
        </div>

        {/* Product Table */}
        <div className="mt-8">
            <h2 className="text-lg font-semibold mb-4 text-gray-700">Current Catalog Items</h2>

            <div className="overflow-x-auto border border-gray-400">
                <table className="min-w-full divide-y divide-gray-300">
                    <thead className="bg-gray-200">
                        <tr>
                            <th className="px-4 py-2 text-left text-xs font-medium text-gray-700 uppercase">Name</th>
                            <th className="px-4 py-2 text-left text-xs font-medium text-gray-700 uppercase">Price</th>
                            <th className="px-4 py-2 text-left text-xs font-medium text-gray-700 uppercase">Discount</th>
                            <th className="px-4 py-2 text-left text-xs font-medium text-gray-700 uppercase">Stock</th>
                            <th className="px-4 py-2 text-left text-xs font-medium text-gray-700 uppercase">Unit</th>
                            <th className="px-4 py-2 text-center text-xs font-medium text-gray-700 uppercase">Actions</th>
                        </tr>
                    </thead>

                    <tbody className="bg-white divide-y divide-gray-300">
                        {productList.map(product => (
                            <tr key={product.id}>
                                <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">{product.name}</td>
                                <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-600">${product.price.toFixed(2)}</td>
                                <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-600">{product.discount}%</td>
                                <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-600">{product.stock}</td>
                                <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-600">{product.unit}</td>

                                <td className="px-4 py-3 whitespace-nowrap text-center text-sm">
                                    <button
                                        onClick={() => enterEditMode(product)}
                                        className="text-gray-700 hover:text-gray-900 text-xs mr-2 border border-gray-700 px-2 py-1"
                                    >
                                        Edit
                                    </button>

                                    <button
                                        onClick={() => manageProductDelete(product.id)}
                                        className="text-red-700 hover:text-red-900 text-xs border border-red-700 px-2 py-1"
                                    >
                                        Delete
                                    </button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>

                {productList.length === 0 && (
                    <div className="text-center py-4 text-gray-500 bg-white">
                        No products in catalog. Add one above.
                    </div>
                )}
            </div>
        </div>
    </div>
);


// --- MAIN APP LOGIC WITH EDIT FEATURE ADDED ---

const initialProducts = [
    { id: 1, name: 'Organic Heirloom Tomatoes', price: 4.99, discount: 10, stock: 150, unit: 'kg' },
    { id: 2, name: 'Artisan Sourdough Bread', price: 6.50, discount: 0, stock: 45, unit: 'loaf' },
    { id: 3, name: 'Free-Range Chicken Eggs (Dozen)', price: 3.75, discount: 15, stock: 200, unit: 'dozen' },
];

const initialPendingRequests = [
    { id: 1, name: "John Doe", email: "john@example.com", date: "2025-01-14" },
    { id: 2, name: "Emily Carter", email: "emily@example.com", date: "2025-02-01" },
];

const initialAcceptedRequests = [
    { id: 9, name: "Mark Lee", email: "mark@example.com", date: "2025-01-01" },
];

const RequestsView = ({
    pendingRequests,
    acceptedRequests,
    rejectedRequests,
    blockedRequests,
    requestViewType,
    setRequestViewType,
    acceptRequest,
    rejectRequest,
    blockRequest,
    setView
}) => (
    <div className="p-6 border border-gray-400 bg-white w-full max-w-4xl mx-auto">

        {/* Header */}
        <div className="flex items-center justify-between mb-6 border-b pb-3">
            <h1 className="text-2xl font-bold text-gray-800">🔗 Link Requests</h1>

            <button
                onClick={() => setView("dashboard")}
                className="bg-gray-700 text-white px-4 py-2 rounded-lg hover:bg-gray-600 transition"
            >
                Back to Catalog
            </button>
        </div>

        {/* Buttons */}
        <div className="flex space-x-4 mb-6">
            <button
                onClick={() => setRequestViewType("pending")}
                className={`px-4 py-2 border ${requestViewType === "pending" ? "bg-gray-700 text-white" : "bg-white text-gray-700"} `}
            >
                Pending Requests
            </button>

            <button
                onClick={() => setRequestViewType("accepted")}
                className={`px-4 py-2 border ${requestViewType === "accepted" ? "bg-gray-700 text-white" : "bg-white text-gray-700"} `}
            >
                Accepted Requests
            </button>

            <button
                onClick={() => setRequestViewType("rejected")}
                className={`px-4 py-2 border ${requestViewType === "rejected" ? "bg-gray-700 text-white" : "bg-white text-gray-700"} `}
            >
                Rejected Requests
            </button>

            <button
                onClick={() => setRequestViewType("blocked")}
                className={`px-4 py-2 border ${requestViewType === "blocked" ? "bg-gray-700 text-white" : "bg-white text-gray-700"} `}
            >
                Blocked Requests
            </button>
        </div>

        {/* Pending Requests Table */}
        {requestViewType === "pending" && (
            <div className="border border-gray-400">
                <table className="min-w-full divide-y divide-gray-300">
                    <thead className="bg-gray-200 text-gray-700">
                        <tr>
                            <th className="px-4 py-2">ID</th>
                            <th className="px-4 py-2">Consumer Name</th>
                            <th className="px-4 py-2">Email</th>
                            <th className="px-4 py-2">Date</th>
                            <th className="px-4 py-2 text-center">Actions</th>
                        </tr>
                    </thead>

                    <tbody className="bg-white divide-y divide-gray-300 text-gray-700">
                        {pendingRequests.map(req => (
                            <tr key={req.id}>
                                <td className="px-4 py-2">{req.id}</td>
                                <td className="px-4 py-2">{req.name}</td>
                                <td className="px-4 py-2">{req.email}</td>
                                <td className="px-4 py-2">{req.date}</td>

                                <td className="px-4 py-2 text-center space-x-2">
                                    <button
                                        onClick={() => acceptRequest(req.id)}
                                        className="px-2 py-1 border border-green-700 text-green-700 hover:bg-green-100 text-xs"
                                    >
                                        Accept
                                    </button>
                                    <button
                                        onClick={() => rejectRequest(req.id)}
                                        className="px-2 py-1 border border-yellow-700 text-yellow-700 hover:bg-yellow-100 text-xs"
                                    >
                                        Reject
                                    </button>
                                    <button
                                        onClick={() => blockRequest(req.id)}
                                        className="px-2 py-1 border border-red-700 text-red-700 hover:bg-red-100 text-xs"
                                    >
                                        Block
                                    </button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>

                {pendingRequests.length === 0 && (
                    <div className="p-4 text-center text-gray-600">No pending requests.</div>
                )}
            </div>
        )}

        {/* Accepted Requests Table */}
        {requestViewType === "accepted" && (
            <div className="border border-gray-400">
                <table className="min-w-full divide-y divide-gray-300">
                    <thead className="bg-gray-200 text-gray-700">
                        <tr>
                            <th className="px-4 py-2">ID</th>
                            <th className="px-4 py-2">Consumer Name</th>
                            <th className="px-4 py-2">Email</th>
                            <th className="px-4 py-2">Date</th>
                        </tr>
                    </thead>

                    <tbody className="bg-white divide-y divide-gray-300 text-gray-700">
                        {acceptedRequests.map(req => (
                            <tr key={req.id}>
                                <td className="px-4 py-2">{req.id}</td>
                                <td className="px-4 py-2">{req.name}</td>
                                <td className="px-4 py-2">{req.email}</td>
                                <td className="px-4 py-2">{req.date}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>

                {acceptedRequests.length === 0 && (
                    <div className="p-4 text-center text-gray-600">No accepted requests yet.</div>
                )}
            </div>
        )}

        {requestViewType === "rejected" && (
            <div className="border border-gray-400">
                <table className="min-w-full divide-y divide-gray-300">
                    <thead className="bg-gray-200 text-gray-700">
                        <tr>
                            <th className="px-4 py-2">ID</th>
                            <th className="px-4 py-2">Consumer Name</th>
                            <th className="px-4 py-2">Email</th>
                            <th className="px-4 py-2">Date</th>
                        </tr>
                    </thead>

                    <tbody className="bg-white divide-y divide-gray-300 text-gray-700">
                        {rejectedRequests.map(req => (
                            <tr key={req.id}>
                                <td className="px-4 py-2">{req.id}</td>
                                <td className="px-4 py-2">{req.name}</td>
                                <td className="px-4 py-2">{req.email}</td>
                                <td className="px-4 py-2">{req.date}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>

                {rejectedRequests.length === 0 && (
                    <div className="p-4 text-center text-gray-600">No rejected requests.</div>
                )}
            </div>
        )}

        {requestViewType === "blocked" && (
            <div className="border border-gray-400">
                <table className="min-w-full divide-y divide-gray-300">
                    <thead className="bg-gray-200 text-gray-700">
                        <tr>
                            <th className="px-4 py-2">ID</th>
                            <th className="px-4 py-2">Consumer Name</th>
                            <th className="px-4 py-2">Email</th>
                            <th className="px-4 py-2">Date</th>
                        </tr>
                    </thead>

                    <tbody className="bg-white divide-y divide-gray-300 text-gray-700">
                        {blockedRequests.map(req => (
                            <tr key={req.id}>
                                <td className="px-4 py-2">{req.id}</td>
                                <td className="px-4 py-2">{req.name}</td>
                                <td className="px-4 py-2">{req.email}</td>
                                <td className="px-4 py-2">{req.date}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>

                {blockedRequests.length === 0 && (
                    <div className="p-4 text-center text-gray-600">No blocked requests.</div>
                )}
            </div>
        )}



    </div>
);




const App = () => {
    const [view, setView] = useState('register');
    const [formData, setFormData] = useState({
        supplierName: '',
        email: '',
        password: '',
        confirmPassword: '',
    });
    const [userId, setUserId] = useState(null);
    const [supplierId, setSupplierId] = useState(null);
    const [productForm, setProductForm] = useState({
        productName: '',
        price: '',
        discount: '',
        stock: '',
        unit: '',
    });

    const [editingProductId, setEditingProductId] = useState(null);

    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const [productList, setProductList] = useState(initialProducts);
    const [message, setMessage] = useState('');
    const [successMessage, setSuccessMessage] = useState('');

    const [pendingRequests, setPendingRequests] = useState(initialPendingRequests);
    const [acceptedRequests, setAcceptedRequests] = useState(initialAcceptedRequests);
    const [rejectedRequests, setRejectedRequests] = useState([]);
    const [blockedRequests, setBlockedRequests] = useState([]);

    const [requestViewType, setRequestViewType] = useState("pending");
    // "pending" or "accepted"



    const manageChange = (e) => {
        const { id, value } = e.target;
        setFormData(prev => ({ ...prev, [id]: value }));
        setError('');
        setMessage('');
    };


    // ---------- VALIDATION ----------
    const verifyForm = () => {
        if (!formData.supplierName || !formData.email || !formData.password || !formData.confirmPassword) {
            setError("Please fill in all fields.");
            return false;
        }
        if (formData.password !== formData.confirmPassword) {
            setError("Passwords do not match.");
            return false;
        }
        return true;
    };

    const verifyLoginForm = () => {
        if (!formData.email || !formData.password) {
            setError("Please fill in all fields.");
            return false;
        }
        return true;
    };


    // ---------- REGISTRATION ----------
    // ---------- REGISTRATION ----------
    const manageRegistrationSubmit = async (e) => {
        e.preventDefault();
        if (!verifyForm()) return;

        setLoading(true);
        setError("");
        setMessage("");

        try {
            // Django ожидает: email, password, full_name, supplier_name 
            const payload = {
                email: formData.email,
                password: formData.password,
                full_name: formData.supplierName,    // используем имя компании как имя владельца
                supplier_name: formData.supplierName,
            };

            const data = await apiFetch("/api/auth/register-supplier/", {
                method: "POST",
                body: payload,
            });

            // Можно сразу сохранить userId / supplierId если хочешь
            setUserId(data.user_id);
            setSupplierId(data.supplier_id);

            setMessage("Registration successful! You can now log in.");
            setView("login");
        } catch (err) {
            setError(err.message || "Registration failed");
        } finally {
            setLoading(false);
        }
    };


    // ---------- LOGIN ----------
    // helper для загрузки каталога поставщика
    const loadProducts = async (currentUserId) => {
        try {
            const data = await apiFetch("/api/products/", {
                method: "GET",
                userId: currentUserId, // X-User-Id для RLS :contentReference[oaicite:2]{index=2}
            });

            // ProductSerializer даёт: id, name, price, discount, stock, unit_code/unit_name :contentReference[oaicite:3]{index=3}
            const mapped = (data || []).map(p => ({
                id: p.id,
                name: p.name,
                price: Number(p.price ?? 0),
                discount: Number(p.discount ?? 0),
                stock: Number(p.stock ?? 0),
                unit: p.unit_code || p.unit_name || "",
            }));
            setProductList(mapped);
        } catch (err) {
            setError(err.message || "Failed to load products");
        }
    };

    // ---------- LOGIN ----------
    const manageLoginSubmit = async (e) => {
        e.preventDefault();
        if (!verifyLoginForm()) return;

        setLoading(true);
        setError("");
        setMessage("");

        try {
            // Django LoginView: email, password, login_as ("supplier" / "consumer") :contentReference[oaicite:4]{index=4}
            const payload = {
                email: formData.email,
                password: formData.password,
                login_as: "supplier",
            };

            const data = await apiFetch("/api/auth/login/", {
                method: "POST",
                body: payload,
            });

            if (!data.supplier_id) {
                throw new Error("This account is not linked to a supplier");
            }

            setUserId(data.user_id);
            setSupplierId(data.supplier_id);
            setIsAuthenticated(true);
            setView("dashboard");

            // сразу подтянуть реальный каталог поставщика
            await loadProducts(data.user_id);
        } catch (err) {
            setError(err.message || "Login failed");
        } finally {
            setLoading(false);
        }
    };



    // ---------- PRODUCT UPDATE (EDIT MODE) ----------
    const enterEditMode = (product) => {
        setProductForm({
            productName: product.name,
            price: product.price,
            discount: product.discount,
            stock: product.stock,
            unit: product.unit,
        });
        setEditingProductId(product.id);
    };


    const manageProductUpdate = (e) => {
        const { id, value } = e.target;
        setProductForm(prev => ({ ...prev, [id]: value }));
    };


    const manageAddProduct = async (e) => {
        e.preventDefault();
        setError("");
        setSuccessMessage("");

        if (!productForm.productName || !productForm.price || !productForm.stock || !productForm.unit) {
            setError("Please fill in required fields.");
            return;
        }
        if (!userId) {
            setError("You must be logged in as supplier.");
            return;
        }

        // Django ожидает: sku, name, description, unit_code (kg|liter|pack), price, stock, discount, delivery_time :contentReference[oaicite:5]{index=5}
        const payload = {
            sku: productForm.productName.toLowerCase().replace(/\s+/g, "-"), // простая автогенерация SKU
            name: productForm.productName,
            description: "",
            unit_code: productForm.unit, // убедись, что вводишь kg / liter / pack
            price: productForm.price,
            stock: productForm.stock,
            discount: productForm.discount || 0,
            delivery_time: null,
        };

        try {
            if (editingProductId) {
                // UPDATE: PUT /api/products/<id>/
                await apiFetch(`/api/products/${editingProductId}/`, {
                    method: "PUT",
                    body: payload,
                    userId,
                });

                await loadProducts(userId);
                setSuccessMessage("Product updated successfully!");
                setEditingProductId(null);
            } else {
                // CREATE: POST /api/products/
                await apiFetch("/api/products/", {
                    method: "POST",
                    body: payload,
                    userId,
                });

                await loadProducts(userId);
                setSuccessMessage("Product added successfully!");
            }

            // Reset form
            setProductForm({ productName: "", price: "", discount: "", stock: "", unit: "" });
            setTimeout(() => setSuccessMessage(""), 2000);
        } catch (err) {
            setError(err.message || "Failed to save product");
        }
    };


    const manageProductDelete = async (idToDelete) => {
        if (!userId) {
            setError("You must be logged in as supplier.");
            return;
        }

        try {
            await apiFetch(`/api/products/${idToDelete}/`, {
                method: "DELETE",
                userId,
            });

            await loadProducts(userId);
            setSuccessMessage("Product deleted.");
            setTimeout(() => setSuccessMessage(""), 2000);
        } catch (err) {
            setError(err.message || "Failed to delete product");
        }
    };


    // ------------ REQUEST ACTION HANDLERS ------------ //

    const acceptRequest = (id) => {
        const req = pendingRequests.find(r => r.id === id);
        if (!req) return;

        setPendingRequests(prev => prev.filter(r => r.id !== id));
        setAcceptedRequests(prev => [...prev, req]);
    };

    const rejectRequest = (id) => {
        const req = pendingRequests.find(r => r.id === id);
        if (!req) return;

        setPendingRequests(prev => prev.filter(r => r.id !== id));
        setRejectedRequests(prev => [...prev, req]);
    };

    const blockRequest = (id) => {
        const req = pendingRequests.find(r => r.id === id);
        if (!req) return;

        setPendingRequests(prev => prev.filter(r => r.id !== id));
        setBlockedRequests(prev => [...prev, req]);
    };

    // ---------- RENDER ----------
    if (isAuthenticated && view === "dashboard") {
        return (
            <div className="min-h-screen bg-gray-700 p-8 flex justify-center">
                <CatalogView
                    productForm={productForm}
                    manageAddProduct={manageAddProduct}
                    manageProductUpdate={manageProductUpdate}
                    productList={productList}
                    manageProductDelete={manageProductDelete}
                    successMessage={successMessage}
                    editingProductId={editingProductId}
                    enterEditMode={enterEditMode}

                    setView={setView}
                    setError={setError}
                    setMessage={setMessage}
                />
            </div>
        );
    }

    if (isAuthenticated && view === "requests") {
        return (
            <div className="min-h-screen bg-gray-700 p-8 flex justify-center">
                <RequestsView
                    pendingRequests={pendingRequests}
                    acceptedRequests={acceptedRequests}
                    rejectedRequests={rejectedRequests}
                    blockedRequests={blockedRequests}
                    requestViewType={requestViewType}
                    setRequestViewType={setRequestViewType}
                    acceptRequest={acceptRequest}
                    rejectRequest={rejectRequest}
                    blockRequest={blockRequest}
                    setView={setView}
                />
            </div>
        );
    }



    return (
        <div className="min-h-screen bg-gray-700 flex items-center justify-center p-4">
            <div className="bg-white p-6 w-full max-w-sm border border-gray-400 shadow-xl space-y-4">

                {error && (
                    <div className="bg-red-100 text-red-700 p-3 mb-4 border border-red-500 text-sm font-medium">
                        {error}
                    </div>
                )}

                {message && !error && (
                    <div className="bg-green-100 text-green-700 p-3 mb-4 border border-green-500 text-sm font-medium">
                        {message}
                    </div>
                )}

                {view === "register" ? (
                    <RegistrationForm
                        formData={formData}
                        manageChange={manageChange}
                        manageRegistrationSubmit={manageRegistrationSubmit}
                        loading={loading}
                    />
                ) : (
                    <LoginForm
                        formData={formData}
                        manageChange={manageChange}
                        manageLoginSubmit={manageLoginSubmit}
                        loading={loading}
                    />
                )}

                <div className="text-center text-sm pt-2">
                    {view === "register" ? (
                        <>
                            Already have an account?{" "}
                            <button
                                onClick={() => { setView("login"); setError(""); setMessage(""); }}
                                className="text-gray-700 hover:underline font-medium"
                            >
                                Login here
                            </button>
                        </>
                    ) : (
                        <>
                            Need a supplier account?{" "}
                            <button
                                onClick={() => { setView("register"); setError(""); setMessage(""); }}
                                className="text-gray-700 hover:underline font-medium"
                            >
                                Register here
                            </button>
                        </>
                    )}
                </div>
            </div>
        </div>
    );
};

export default App;
