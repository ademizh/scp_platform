"use client";

import React, { useState } from "react";
import { UserPlus, Loader, Building2, Package } from "lucide-react";

const API_BASE_URL =
    process.env.NEXT_PUBLIC_API_BASE_URL || "http://127.0.0.1:8000";
async function apiFetch(path, { method = "GET", body, userId } = {}) {
    const headers = {
        "Content-Type": "application/json",
    };

    if (userId) {
        headers["X-User-Id"] = String(userId);
    }

    const res = await fetch(`${API_BASE_URL}${path}`, {
        method,
        headers,
        body: body ? JSON.stringify(body) : undefined,
    });

    if (res.status === 204) return null;

    let data = null;
    try {
        data = await res.json();
    } catch {
    }

    if (!res.ok) {
        let msg = "Server error";

        if (data) {
            if (typeof data === "string") {
                msg = data;
            } else if (data.detail) {
                msg = data.detail;
            } else {
                const keys = Object.keys(data);
                if (keys.length > 0) {
                    const firstVal = data[keys[0]];
                    if (Array.isArray(firstVal) && firstVal.length > 0) {
                        msg = firstVal[0];
                    } else if (typeof firstVal === "string") {
                        msg = firstVal;
                    }
                }
            }
        }

        throw new Error(msg);
    }

    return data;
}


const RegistrationForm = ({ formData, manageChange, manageRegistrationSubmit, loading }) => (
    <form onSubmit={manageRegistrationSubmit} className="space-y-4">
        <h2 className="text-xl font-bold mb-4 text-gray-800">Register Supplier Account</h2>

        <div>
            <label htmlFor="supplierName" className="block text-sm font-medium mb-1 text-gray-700">Supplier/Company Name</label>
            <div className="flex items-center border border-gray-400 p-2">
                <Building2 className="h-4 w-4 text-gray-500 mr-2" />
                <input id="supplierName" type="text" className="w-full outline-none text-gray-900"
                    onChange={manageChange} value={formData.supplierName} placeholder="Company Name" required />
            </div>
        </div>

        <div>
            <label htmlFor="email" className="block text-sm font-medium mb-1 text-gray-700">Business Email</label>
            <input id="email" type="email" className="w-full border border-gray-400 p-2 text-gray-900"
                onChange={manageChange} value={formData.email} placeholder="email@example.com" required />
        </div>

        <div>
            <label htmlFor="password" className="block text-sm font-medium mb-1 text-gray-700">Password</label>
            <input id="password" type="password" className="w-full border border-gray-400 p-2 text-gray-900"
                onChange={manageChange} value={formData.password} placeholder="••••••••" required />
        </div>

        <div>
            <label htmlFor="confirmPassword" className="block text-sm font-medium mb-1 text-gray-700">Confirm Password</label>
            <input id="confirmPassword" type="password" className="w-full border border-gray-400 p-2 text-gray-900"
                onChange={manageChange} value={formData.confirmPassword} placeholder="••••••••" required />
        </div>

        <button type="submit" className="w-full bg-gray-700 text-white py-2 mt-4 flex items-center justify-center hover:bg-gray-600 transition duration-150" disabled={loading}>
            {loading ? (<><Loader className="h-4 w-4 mr-2 animate-spin" /> Processing...</>) : (<><UserPlus className="h-4 w-4 mr-2" /> Register Supplier Account</>)}
        </button>
    </form>
);

const LoginForm = ({ formData, manageChange, manageLoginSubmit, loading }) => (
    <form onSubmit={manageLoginSubmit} className="space-y-4">
        <h2 className="text-xl font-bold mb-4 text-gray-800">Supplier Login</h2>

        <div>
            <label htmlFor="email" className="block text-sm font-medium mb-1 text-gray-700">Email Address</label>
            <input type="email" id="email" value={formData.email} onChange={manageChange} className="w-full border border-gray-400 p-2 text-gray-900" placeholder="email@company.com" required />
        </div>

        <div>
            <label htmlFor="password" className="block text-sm font-medium mb-1 text-gray-700">Password</label>
            <input type="password" id="password" value={formData.password} onChange={manageChange} className="w-full border border-gray-400 p-2 text-gray-900" placeholder="Enter password" required />
        </div>

        <button type="submit" className="w-full bg-gray-700 text-white py-2 mt-4 flex items-center justify-center hover:bg-gray-600 transition duration-150" disabled={loading}>
            {loading ? (<><Loader className="h-4 w-4 mr-2 animate-spin" /> Logging in...</>) : ("Log In as Supplier")}
        </button>
    </form>
);

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
        <div className="flex items-center justify-between mb-6 border-b pb-3">
            <h1 className="text-2xl font-bold text-gray-800">🔗 Link Requests</h1>
            <button
                onClick={() => setView("dashboard")}
                className="bg-gray-700 text-white px-4 py-2 rounded-lg hover:bg-gray-600 transition"
            >
                Back to Catalog
            </button>
        </div>

        <div className="flex space-x-4 mb-6">
            <button onClick={() => setRequestViewType("pending")} className={`px-4 py-2 border ${requestViewType === "pending" ? "bg-gray-700 text-white" : "bg-white text-gray-700"}`}>Pending</button>
            <button onClick={() => setRequestViewType("accepted")} className={`px-4 py-2 border ${requestViewType === "accepted" ? "bg-gray-700 text-white" : "bg-white text-gray-700"}`}>Accepted</button>
            <button onClick={() => setRequestViewType("rejected")} className={`px-4 py-2 border ${requestViewType === "rejected" ? "bg-gray-700 text-white" : "bg-white text-gray-700"}`}>Rejected</button>
            <button onClick={() => setRequestViewType("blocked")} className={`px-4 py-2 border ${requestViewType === "blocked" ? "bg-gray-700 text-white" : "bg-white text-gray-700"}`}>Blocked</button>
        </div>

        {/* Pending */}
        {requestViewType === "pending" && (
            <div className="border border-gray-400">
                <table className="min-w-full divide-y divide-gray-300">
                    <thead className="bg-gray-200 text-gray-700">
                        <tr>
                            <th className="px-4 py-2">ID</th>
                            <th className="px-4 py-2">Consumer Name</th>
                            <th className="px-4 py-2">Date</th>
                            <th className="px-4 py-2 text-center">Actions</th>
                        </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-300 text-gray-700">
                        {pendingRequests.map(req => (
                            <tr key={req.id}>
                                <td className="px-4 py-2">{req.id}</td>
                                <td className="px-4 py-2">{req.name}</td>
                                <td className="px-4 py-2">{req.date}</td>
                                <td className="px-4 py-2 text-center space-x-2">
                                    <button onClick={() => acceptRequest(req.id)} className="px-2 py-1 border border-green-700 text-green-700 hover:bg-green-100 text-xs">Accept</button>
                                    <button onClick={() => rejectRequest(req.id)} className="px-2 py-1 border border-yellow-700 text-yellow-700 hover:bg-yellow-100 text-xs">Reject</button>
                                    <button onClick={() => blockRequest(req.id)} className="px-2 py-1 border border-red-700 text-red-700 hover:bg-red-100 text-xs">Block</button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
                {pendingRequests.length === 0 && <div className="p-4 text-center text-gray-600">No pending requests.</div>}
            </div>
        )}

        {requestViewType === "accepted" && (
            <div className="border border-gray-400">
                <table className="min-w-full divide-y divide-gray-300">
                    <thead className="bg-gray-200 text-gray-700">
                        <tr>
                            <th className="px-4 py-2">ID</th>
                            <th className="px-4 py-2">Consumer Name</th>
                            <th className="px-4 py-2">Date</th>
                        </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-300 text-gray-700">
                        {acceptedRequests.map(req => (
                            <tr key={req.id}>
                                <td className="px-4 py-2">{req.id}</td>
                                <td className="px-4 py-2">{req.name}</td>
                                <td className="px-4 py-2">{req.date}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
                {acceptedRequests.length === 0 && <div className="p-4 text-center text-gray-600">No accepted requests yet.</div>}
            </div>
        )}


        {requestViewType === "rejected" && (
            <div className="border border-gray-400">
                <table className="min-w-full divide-y divide-gray-300">
                    <thead className="bg-gray-200 text-gray-700">
                        <tr>
                            <th className="px-4 py-2">ID</th>
                            <th className="px-4 py-2">Consumer Name</th>
                            <th className="px-4 py-2">Date</th>
                        </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-300 text-gray-700">
                        {rejectedRequests.map(req => (
                            <tr key={req.id}>
                                <td className="px-4 py-2">{req.id}</td>
                                <td className="px-4 py-2">{req.name}</td>
                                <td className="px-4 py-2">{req.date}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
                {rejectedRequests.length === 0 && <div className="p-4 text-center text-gray-600">No rejected requests.</div>}
            </div>
        )}

        {requestViewType === "blocked" && (
            <div className="border border-gray-400">
                <table className="min-w-full divide-y divide-gray-300">
                    <thead className="bg-gray-200 text-gray-700">
                        <tr>
                            <th className="px-4 py-2">ID</th>
                            <th className="px-4 py-2">Consumer Name</th>
                            <th className="px-4 py-2">Date</th>
                        </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-300 text-gray-700">
                        {blockedRequests.map(req => (
                            <tr key={req.id}>
                                <td className="px-4 py-2">{req.id}</td>
                                <td className="px-4 py-2">{req.name}</td>
                                <td className="px-4 py-2">{req.date}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
                {blockedRequests.length === 0 && <div className="p-4 text-center text-gray-600">No blocked requests.</div>}
            </div>
        )}

    </div>
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
    setMessage,
    setIsAuthenticated,
    setCurrentUser,

    isOwner,
    isManager,
    goToUserManagement,
    goToOrders,
    goToRequests,
    goToComplaints,
    error,
}) => (
    <div className="p-6 border border-gray-400 bg-white w-full max-w-4xl mx-auto">
        <div className="flex items-center justify-between mb-6 border-b pb-3">
            <h1 className="text-2xl font-bold text-gray-800">📦 Supplier Catalog Dashboard</h1>
            <div className="flex items-center space-x-3">
                {(isOwner || isManager) && <button onClick={goToRequests} className="bg-gray-700 text-white px-4 py-2 rounded-lg hover:bg-gray-600 transition">View Requests</button>}
                {isOwner && <button onClick={goToUserManagement} className="bg-gray-700 text-white px-4 py-2 rounded-lg hover:bg-gray-600 transition">User Management</button>}
                {(isOwner || isManager) && (
                    <button
                        onClick={goToOrders}
                        className="bg-gray-700 text-white px-4 py-2 rounded-lg hover:bg-gray-600 transition"
                    >
                        Orders
                    </button>
                )}
                {(isManager || isOwner) && (
                    <button
                        onClick={goToComplaints}
                        className="bg-gray-700 text-white px-4 py-2 rounded-lg hover:bg-gray-600 transition"
                    >
                        Complaints
                    </button>
                )}
                <button
                    onClick={() => {
                        setIsAuthenticated(false);
                        setCurrentUser(null);
                        setView("login");
                        setError("");
                        setMessage("");
                    }}
                    className="bg-gray-700 text-white px-4 py-2 rounded-lg hover:bg-gray-600 transition">
                    Log Out
                </button>
            </div>
        </div>

        {successMessage && (
            <div className="bg-green-100 text-green-700 p-3 mb-4 border border-green-500 text-sm">
                {successMessage}
            </div>
        )}

        <div className="mb-8 p-4 border border-gray-400 bg-gray-50">
            <h2 className="text-lg font-semibold mb-4 text-gray-700">{editingProductId ? "Update Product" : "Add Product"}</h2>

            <form onSubmit={manageAddProduct} className="space-y-3">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label htmlFor="productName" className="block text-sm font-medium text-gray-700">Name</label>
                        <input id="productName" type="text" className="w-full border border-gray-400 p-2 text-gray-900"
                            onChange={manageProductUpdate} value={productForm.productName} required />
                    </div>

                    <div>
                        <label htmlFor="price" className="block text-sm font-medium text-gray-700">Price ($)</label>
                        <input id="price" type="number" className="w-full border border-gray-400 p-2 text-gray-900"
                            onChange={manageProductUpdate} value={productForm.price} required />
                    </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label htmlFor="stock" className="block text-sm font-medium text-gray-700">Stock</label>
                        <input id="stock" type="number" className="w-full border border-gray-400 p-2 text-gray-900"
                            onChange={manageProductUpdate} value={productForm.stock} required />
                    </div>

                    <div>
                        <label htmlFor="unit" className="block text-sm font-medium text-gray-700">Unit</label>
                        <input id="unit" type="text" className="w-full border border-gray-400 p-2 text-gray-900"
                            onChange={manageProductUpdate} value={productForm.unit} required />
                    </div>

                    <div>
                        <label htmlFor="discount" className="block text-sm font-medium text-gray-700">Discount (%)</label>
                        <input id="discount" type="number" className="w-full border border-gray-400 p-2 text-gray-900"
                            onChange={manageProductUpdate} value={productForm.discount} />
                    </div>
                </div>

                <div>
                    <label htmlFor="image" className="block text-sm font-medium text-gray-700">Image</label>
                    <input id="image" type="file" accept="image/*" className="w-full border border-gray-400 p-2 text-gray-900"
             />
                </div>

                <button type="submit" className="w-full bg-gray-700 text-white py-2 hover:bg-gray-600 transition duration-150">
                    <Package className="h-4 w-4 mr-2 inline" /> {editingProductId ? "Update Product" : "Add Product"}
                </button>
            </form>
        </div>

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
                            <th className="px-4 py-2 text-left text-xs font-medium text-gray-700 uppercase">Image</th>
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
                                <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-600"></td>
                                <td className="px-4 py-3 whitespace-nowrap text-sm">
                                    <span className="text-gray-400 text-xs">No image</span>
                                </td>
                                <td className="px-4 py-3 whitespace-nowrap text-center text-sm">
                                    <button onClick={() => enterEditMode(product)} className="text-gray-700 hover:text-gray-900 text-xs mr-2 border border-gray-700 px-2 py-1">Edit</button>
                                    <button onClick={() => manageProductDelete(product.id)} className="text-red-700 hover:text-red-900 text-xs border border-red-700 px-2 py-1">Delete</button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>

                {productList.length === 0 && <div className="text-center py-4 text-gray-500 bg-white">No products in catalog. Add one above.</div>}
            </div>
        </div>
    </div>
);

const UserManagementView = ({
    managers,
    sales,
    createManager,
    createSales,
    removeManager,
    removeSales,
    setView,
    deleteSupplierAccount
}) => {
    const [mgrForm, setMgrForm] = useState({ name: "", email: "", password: "" });
    const [salesForm, setSalesForm] = useState({ name: "", email: "", password: "" });

    return (
        <div className="p-6 border border-gray-400 bg-white w-full max-w-4xl mx-auto">
            <div className="flex items-center justify-between mb-6 border-b pb-3">
                <h1 className="text-2xl font-bold text-gray-800">👥 User Management</h1>
                <div className="flex items-center space-x-3">
                    <button onClick={() => setView("dashboard")} className="bg-gray-700 text-white px-4 py-2 rounded-lg hover:bg-gray-600 transition">Back to Catalog</button>
                    <button onClick={() => { if (confirm("Delete supplier account? This will deactivate and archive data (local simulation). Proceed?")) deleteSupplierAccount(); }} className="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-500 transition">Delete Supplier Account</button>
                </div>
            </div>

            <div className="grid md:grid-cols-2 gap-6">
                <div className="p-4 border border-gray-300 bg-gray-50">
                    <h3 className="text-lg text-gray-700 font-semibold mb-3">Create Manager</h3>
                    <div className="space-y-2">
                        <input type="text" placeholder="Name" value={mgrForm.name} onChange={(e) => setMgrForm(prev => ({ ...prev, name: e.target.value }))} className="w-full border p-2 text-gray-700" />
                        <input type="email" placeholder="Email" value={mgrForm.email} onChange={(e) => setMgrForm(prev => ({ ...prev, email: e.target.value }))} className="w-full border p-2 text-gray-700" />
                        <input type="password" placeholder="Password" value={mgrForm.password} onChange={(e) => setMgrForm(prev => ({ ...prev, password: e.target.value }))} className="w-full border p-2 text-gray-700" />
                        <button onClick={() => { createManager(mgrForm); setMgrForm({ name: "", email: "", password: "" }); }} className="mt-2 bg-gray-700 text-white px-3 py-2">Create Manager</button>
                    </div>
                </div>

                <div className="p-4 border border-gray-300 bg-gray-50">
                    <h3 className="text-lg text-gray-700 font-semibold mb-3">Create Sales Representative</h3>
                    <div className="space-y-2">
                        <input type="text" placeholder="Name" value={salesForm.name} onChange={(e) => setSalesForm(prev => ({ ...prev, name: e.target.value }))} className="w-full border p-2 text-gray-700" />
                        <input type="email" placeholder="Email" value={salesForm.email} onChange={(e) => setSalesForm(prev => ({ ...prev, email: e.target.value }))} className="w-full border p-2 text-gray-700" />
                        <input type="password" placeholder="Password" value={salesForm.password} onChange={(e) => setSalesForm(prev => ({ ...prev, password: e.target.value }))} className="w-full border p-2 text-gray-700" />
                        <button onClick={() => { createSales(salesForm); setSalesForm({ name: "", email: "", password: "" }); }} className="mt-2 bg-gray-700 text-white px-3 py-2">Create Sales</button>
                    </div>
                </div>
            </div>

            <div className="mt-6 grid md:grid-cols-2 gap-6">
                <div className="p-4 border border-gray-300">
                    <h4 className="font-semibold text-gray-700 mb-2">Managers</h4>
                    <table className="min-w-full">
                        <thead>
                            <tr className="text-left text-xs text-gray-600">
                                <th className="px-2">ID</th><th className="px-2">Name</th><th className="px-2">Email</th><th className="px-2">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            {managers.map(m => (
                                <tr key={m.id} className="text-sm text-gray-700">
                                    <td className="px-2 py-2">{m.id}</td>
                                    <td className="px-2 py-2">{m.name}</td>
                                    <td className="px-2 py-2">{m.email}</td>
                                    <td className="px-2 py-2"><button onClick={() => removeManager(m.id)} className="text-red-600">Remove</button></td>
                                </tr>
                            ))}
                            {managers.length === 0 && <tr><td colSpan="4" className="p-2 text-gray-500">No managers yet.</td></tr>}
                        </tbody>
                    </table>
                </div>

                <div className="p-4 border border-gray-300">
                    <h4 className="font-semibold text-gray-700 mb-2">Sales Representatives</h4>
                    <table className="min-w-full">
                        <thead>
                            <tr className="text-left text-xs text-gray-600">
                                <th className="px-2">ID</th><th className="px-2">Name</th><th className="px-2">Email</th><th className="px-2">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            {sales.map(s => (
                                <tr key={s.id} className="text-sm text-gray-700">
                                    <td className="px-2 py-2">{s.id}</td>
                                    <td className="px-2 py-2">{s.name}</td>
                                    <td className="px-2 py-2">{s.email}</td>
                                    <td className="px-2 py-2"><button onClick={() => removeSales(s.id)} className="text-red-600">Remove</button></td>
                                </tr>
                            ))}
                            {sales.length === 0 && <tr><td colSpan="4" className="p-2 text-gray-500">No sales reps yet.</td></tr>}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
};

const OrderView = ({
    pendingOrders,
    acceptedOrders,
    rejectedOrders,
    successMessage,
    orderStatus,
    setOrderStatus,
    acceptOrder,
    rejectOrder,
    productList,

    setView,
    setError,
    setMessage,

}) => (
    <div className="p-6 border border-gray-400 bg-white w-full max-w-4xl mx-auto">
        <div className="flex items-center justify-between mb-6 border-b pb-3">
            <h1 className="text-2xl font-bold text-gray-800">🔗 Orders</h1>
            <button onClick={() => setView("dashboard")} className="bg-gray-700 text-white px-4 py-2 rounded-lg hover:bg-gray-600 transition">Back to Catalog</button>
        </div>

        <div className="flex space-x-4 mb-6">
            <button onClick={() => setOrderStatus("pending")}
                className={`px-4 py-2 border ${orderStatus === "pending" ? "bg-gray-700 text-white" : "bg-white text-gray-700"}`}>Pending</button>
            <button onClick={() => setOrderStatus("accepted")}
                className={`px-4 py-2 border ${orderStatus === "accepted" ? "bg-gray-700 text-white" : "bg-white text-gray-700"}`}>Accepted</button>
            <button onClick={() => setOrderStatus("rejected")}
                className={`px-4 py-2 border ${orderStatus === "rejected" ? "bg-gray-700 text-white" : "bg-white text-gray-700"}`}>Rejected</button>
        </div>

        {orderStatus === "pending" && (
            <div className="border border-gray-400">
                <table className="min-w-full divide-y divide-gray-300">
                    <thead className="bg-gray-200 text-gray-700">
                        <tr>
                            <th className="px-4 py-2">Order ID</th>
                            <th className="px-4 py-2">Consumer Name</th>
                            <th className="px-4 py-2">Date</th>
                            <th className="px-4 py-2">Products</th>
                            <th className="px-4 py-2">Total Amount</th>
                            <th className="px-4 py-2 text-center">Actions</th>
                        </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-300 text-gray-700">
                        {pendingOrders.map(order => (
                            <tr key={order.id}>
                                <td className="px-4 py-2">{order.id}</td>
                                <td className="px-4 py-2">{order.consumerName}</td>
                                <td className="px-4 py-2">{order.date}</td>
                                <td className="px-4 py-2">{
                                    order.products.map(prod => `${prod.name} - ${prod.units} units`)
                                        .join("\n")
                                }</td>
                                <td className="px-4 py-2">
                                    {`$${order.totalAmount.toFixed(2)}`}
                                </td>

                                <td className="px-4 py-2">
                                    ${order.products.reduce((sum, item) => {
                                        const product = productList.find(p => p.id === item.id);
                                        if (!product) return sum;

                                        const rawPrice = Number(product.amount);
                                        const discount = Number(product.discount || 0);

                                        const discountedPrice = rawPrice * (1 - discount / 100);

                                        return sum + discountedPrice * Number(item.units);

                                    }, 0).toFixed(2)}
                                </td>
                                <td className="px-4 py-2 text-center space-x-2">
                                    <button onClick={() => acceptOrder(order.id)} className="px-2 py-1 border border-green-700 text-green-700 hover:bg-green-100 text-xs">Accept</button>
                                    <button onClick={() => rejectOrder(order.id)} className="px-2 py-1 border border-yellow-700 text-yellow-700 hover:bg-yellow-100 text-xs">Reject</button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
                {pendingOrders.length === 0 && <div className="p-4 text-center text-gray-600">No pending orders.</div>}
            </div>
        )}

        {orderStatus === "accepted" && (
            <div className="border border-gray-400">
                <table className="min-w-full divide-y divide-gray-300">
                    <thead className="bg-gray-200 text-gray-700">
                        <tr>
                            <th className="px-4 py-2">Order ID</th>
                            <th className="px-4 py-2">Consumer Name</th>
                            <th className="px-4 py-2">Date</th>
                            <th className="px-4 py-2">Products</th>
                            <th className="px-4 py-2">Total Amount</th>
                        </tr>
                    </thead>

                    <tbody className="bg-white divide-y divide-gray-300 text-gray-700">
                        {acceptedOrders.filter(Boolean).map(order => (
                            <tr key={order.id}>
                                <td className="px-4 py-2">{order.id}</td>
                                <td className="px-4 py-2">{order.consumerName}</td>
                                <td className="px-4 py-2">{order.date}</td>
                                <td className="px-4 py-2 whitespace-pre-line">
                                    {order.products.map(p => `${p.name} — ${p.units} units`).join("\n")}
                                </td>
                                <td className="px-4 py-2">
                                    {`$${order.totalAmount.toFixed(2)}`}
                                </td>

                                <td className="px-4 py-2">
                                    ${order.products.reduce((sum, item) => {
                                        const product = productList.find(p => p.id === item.id);
                                        if (!product) return sum;

                                        const rawPrice = Number(product.amount);
                                        const discount = Number(product.discount || 0);

                                        const discountedPrice = rawPrice * (1 - discount / 100);

                                        return sum + discountedPrice * Number(item.units);

                                    }, 0).toFixed(2)}
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>

                {acceptedOrders.length === 0 && (
                    <div className="p-4 text-center text-gray-600">No accepted orders.</div>
                )}
            </div>
        )}

        {orderStatus === "rejected" && (
            <div className="border border-gray-400">
                <table className="min-w-full divide-y divide-gray-300">
                    <thead className="bg-gray-200 text-gray-700">
                        <tr>
                            <th className="px-4 py-2">ID</th>
                            <th className="px-4 py-2">Consumer Name</th>
                            <th className="px-4 py-2">Date</th>
                            <th className="px-4 py-2">Products</th>
                            <th className="px-4 py-2">Total Amount</th>
                        </tr>
                    </thead>

                    <tbody className="bg-white divide-y divide-gray-300 text-gray-700">
                        {rejectedOrders.filter(Boolean).map(order => (
                            <tr key={order.id}>
                                <td className="px-4 py-2">{order.id}</td>
                                <td className="px-4 py-2">{order.consumerName}</td>
                                <td className="px-4 py-2">{order.date}</td>
                                <td className="px-4 py-2 whitespace-pre-line">
                                    {order.products.map(p => `${p.name} — ${p.units} units`).join("\n")}
                                </td>
                                <td className="px-4 py-2">
                                    {`$${order.totalAmount.toFixed(2)}`}
                                </td>

                                <td className="px-4 py-2">
                                    ${order.products.reduce((sum, item) => {
                                        const product = productList.find(p => p.id === item.id);
                                        if (!product) return sum;

                                        const rawPrice = Number(amount.price);
                                        const discount = Number(product.discount || 0);

                                        const discountedPrice = rawPrice * (1 - discount / 100);

                                        return sum + discountedPrice * Number(item.units);

                                    }, 0).toFixed(2)}
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>

                {rejectedOrders.length === 0 && (
                    <div className="p-4 text-center text-gray-600">No rejected orders.</div>
                )}
            </div>
        )}
    </div>
)

const ComplaintsView = ({
    escalatedComplaints,
    resolvedComplaints,
    complaintViewType,
    setComplaintViewType,
    setView,
    isManager,
    isOwner,
    resolveComplaint,
}) => (
    <div className="min-h-screen bg-gray-700 p-8">
        <div className="p-6 border min-h-[90vh] border-gray-400 bg-white w-full max-w-4xl mx-auto">

            <div className="flex items-center justify-between mb-6 border-b pb-3">
                <h1 className="text-2xl font-bold text-gray-800">Complaints</h1>
                <button
                    onClick={() => setView("dashboard")}
                    className="bg-gray-700 text-white px-4 py-2 rounded-lg hover:bg-gray-600"
                >
                    Back to Catalog
                </button>
            </div>

            <div className="flex space-x-4 mb-6">
                <button
                    onClick={() => setComplaintViewType("escalated")}
                    className={`px-4 py-2 border rounded ${complaintViewType === "escalated"
                        ? "bg-gray-700 text-white border-gray-700"
                        : "bg-white text-gray-700 border-gray-400"
                        }`}
                >
                    Escalated / Open
                </button>
                <button
                    onClick={() => setComplaintViewType("resolved")}
                    className={`px-4 py-2 border rounded ${complaintViewType === "resolved"
                        ? "bg-gray-700 text-white border-gray-700"
                        : "bg-white text-gray-700 border-gray-400"
                        }`}
                >
                    Resolved
                </button>
            </div>

            {complaintViewType === "escalated" && (
                <div className="border border-gray-400 rounded">
                    <table className="min-w-full divide-y divide-gray-300">
                        <thead className="bg-gray-200 text-gray-700">
                            <tr>
                                <th className="px-4 py-2 text-left text-sm font-semibold">ID</th>
                                <th className="px-4 py-2 text-left text-sm font-semibold">Consumer</th>
                                <th className="px-4 py-2 text-left text-sm font-semibold">Status</th>
                                <th className="px-4 py-2 text-left text-sm font-semibold">Text</th>
                                <th className="px-4 py-2 text-left text-sm font-semibold">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="bg-white divide-y divide-gray-300 text-gray-700">
                            {escalatedComplaints.map((c) => (
                                <tr key={c.id}>
                                    <td className="px-4 py-2">{c.id}</td>
                                    <td className="px-4 py-2">{c.consumer}</td>
                                    <td className="px-4 py-2 capitalize">{c.status}</td>
                                    <td className="px-4 py-2">{c.description}</td>
                                    <td className="px-4 py-2 space-x-2">

                                        {(isOwner || isManager) && c.status !== "resolved" && (
                                            <button
                                                onClick={() => resolveComplaint(c.id)}
                                                className="px-2 py-1 border border-green-700 text-green-700 rounded hover:bg-green-100 text-xs"
                                            >
                                                Resolve
                                            </button>
                                        )}
                                    </td>

                                </tr>
                            ))}
                        </tbody>
                    </table>

                    {escalatedComplaints.length === 0 && (
                        <div className="p-4 text-center text-gray-600">
                            No escalated / open complaints.
                        </div>
                    )}
                </div>
            )}


            {complaintViewType === "resolved" && (
                <div className="border border-gray-400 rounded">
                    <table className="min-w-full divide-y divide-gray-300">
                        <thead className="bg-gray-200 text-gray-700">
                            <tr>
                                <th className="px-4 py-2 text-left text-sm font-semibold">ID</th>
                                <th className="px-4 py-2 text-left text-sm font-semibold">Consumer</th>
                                <th className="px-4 py-2 text-left text-sm font-semibold">Text</th>
                            </tr>
                        </thead>
                        <tbody className="bg-white divide-y divide-gray-300 text-gray-700">
                            {resolvedComplaints.map((c) => (
                                <tr key={c.id}>
                                    <td className="px-4 py-2">{c.id}</td>
                                    <td className="px-4 py-2">{c.consumer}</td>
                                    <td className="px-4 py-2">{c.description}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>

                    {resolvedComplaints.length === 0 && (
                        <div className="p-4 text-center text-gray-600">No resolved complaints.</div>
                    )}
                </div>
            )}
        </div>
    </div>
);

const App = () => {
    const [view, setView] = useState("register");

    const [formData, setFormData] = useState({ supplierName: "", email: "", password: "", confirmPassword: "" });
    const [userId, setUserId] = useState(null);
    const [supplierId, setSupplierId] = useState(null);


    const [productForm, setProductForm] = useState({ productName: "", price: "", discount: "", stock: "", unit: "" });
    const [editingProductId, setEditingProductId] = useState(null);


    const [error, setError] = useState("");
    const [message, setMessage] = useState("");
    const [successMessage, setSuccessMessage] = useState("");
    const [loading, setLoading] = useState(false);


    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const [currentUser, setCurrentUser] = useState(null);
    const [supplierActive, setSupplierActive] = useState(true);

    const [productList, setProductList] = useState([]);


    const [users, setUsers] = useState([]);


    const [pendingRequests, setPendingRequests] = useState([]);
    const [acceptedRequests, setAcceptedRequests] = useState([]);
    const [rejectedRequests, setRejectedRequests] = useState([]);
    const [blockedRequests, setBlockedRequests] = useState([]);

    const [requestViewType, setRequestViewType] = useState("pending");



    const [pendingOrders, setPendingOrders] = useState([]);
    const [acceptedOrders, setAcceptedOrders] = useState([]);
    const [rejectedOrders, setRejectedOrders] = useState([]);

    const [orderStatus, setOrderStatus] = useState("pending");


    const [escalatedComplaints, setEscalatedComplaints] = useState([]);
    const [resolvedComplaints, setResolvedComplaints] = useState([]);

    const [complaintViewType, setComplaintViewType] = useState("escalated");


    const nextId = (list) => (list && list.length ? Math.max(...list.map(x => x.id)) + 1 : 1);


    const manageChange = (e) => {
        const { id, value } = e.target;
        setFormData(prev => ({ ...prev, [id]: value }));
        setError("");
        setMessage("");
    };

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


    const manageRegistrationSubmit = async (e) => {
        e.preventDefault();
        if (!verifyForm()) return;

        setLoading(true);
        setError("");
        setMessage("");

        try {
            const payload = {
                email: formData.email,
                password: formData.password,
                full_name: formData.supplierName,
                supplier_name: formData.supplierName,
            };

            const data = await apiFetch("/api/auth/register-supplier/", {
                method: "POST",
                body: payload,
            });

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


    const loadProducts = async (currentUserId) => {
        try {
            const data = await apiFetch("/api/products/", {
                method: "GET",
                userId: currentUserId,
            });

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
    const loadSupplierLinks = async (currentSupplierId) => {
        try {
            const data = await apiFetch(`/api/links/supplier/${currentSupplierId}/`, {
                method: "GET",
            });

            const normalized = (data || []).map((row) => ({
                id: row.id,
                consumerId: row.consumer_id,
                name: row.consumer_name,
                email: row.consumer_email || "",
                date: row.created_at ? new Date(row.created_at).toLocaleString() : "",
                status: row.status,
            }));

            setPendingRequests(normalized.filter((r) => r.status === "pending"));
            setAcceptedRequests(normalized.filter((r) => r.status === "accepted"));

            setRejectedRequests(
                normalized.filter((r) => r.status === "removed" || r.status === "rejected")
            );
            setBlockedRequests(normalized.filter((r) => r.status === "blocked"));
        } catch (err) {
            setError(err.message || "Failed to load link requests");
        }
    };


    const loadSupplierOrders = async (currentUserId) => {
        try {
            const data = await apiFetch("/api/orders/?role=supplier", {
                method: "GET",
                userId: currentUserId,
            });

            const normalized = (data || []).map((o) => ({
                id: o.id,
                consumerName: o.consumer_name,
                email: o.consumer_email || "",
                date: o.created_at ? new Date(o.created_at).toLocaleString() : "",
                status: o.status,
                totalAmount: Number(o.total_amount ?? 0),
                products: (o.items || []).map((it) => ({
                    id: it.product_id,
                    name: it.product_name,
                    units: Number(it.quantity),
                })),
            }));

            setPendingOrders(normalized.filter((o) => o.status === "pending"));
            setAcceptedOrders(normalized.filter((o) => o.status === "accepted"));
            setRejectedOrders(normalized.filter((o) => o.status === "rejected"));
        } catch (err) {
            setError(err.message || "Failed to load orders");
        }
    };
    const loadSupplierStaff = async (currentUserId, currentSupplierId) => {
        try {
            const data = await apiFetch(`/api/suppliers/${currentSupplierId}/staff/`, {
                method: "GET",
                userId: currentUserId,
            });

            const mapped = (data || []).map((s) => ({
                id: s.id,
                name: s.full_name,
                email: s.email,
                role: s.role_code,
            }));

            setUsers(mapped);
        } catch (err) {
            setError(err.message || "Failed to load staff");
        }
    };

    const loadComplaints = async (currentUserId) => {
        if (!supplierId) {
            setError("Supplier is not defined");
            return;
        }

        try {

            const data = await apiFetch(`/api/supplier/${supplierId}/incidents/`, {
                method: "GET",
                userId: currentUserId,
            });

            const mapped = (data || []).map((c) => ({
                id: c.id,
                consumer: c.consumer_id ? `Consumer #${c.consumer_id}` : "",
                description: c.message || "",
                status: c.status,
                assignedTo: c.assigned_to,
            }));


            setEscalatedComplaints(mapped.filter((c) => c.status !== "resolved"));

            setResolvedComplaints(mapped.filter((c) => c.status === "resolved"));
        } catch (err) {
            setError(err.message || "Failed to load complaints");
        }
    };


    const manageLoginSubmit = async (e) => {
        e.preventDefault();
        if (!verifyLoginForm()) return;

        setLoading(true);
        setError("");
        setMessage("");

        try {
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

            const roles = data.roles || [];
            let role = null;

            if (data.login_as === "supplier") {
                if (roles.includes("owner")) role = "owner";
                else if (roles.includes("manager")) role = "manager";
                else if (roles.includes("sales")) role = "sales";
                else role = "supplier";
            } else {
                role = "consumer";
            }
            if (role === "sales") {
                throw new Error(
                    `This email (${formData.email}) belongs to a sales account. Sales must log in via the mobile app, not the web dashboard.`
                );
            }

            setCurrentUser({
                id: data.user_id,
                role,
                email: formData.email,
            });

            setIsAuthenticated(true);
            setView("dashboard");

            await loadProducts(data.user_id);
        } catch (err) {
            setError(err.message || "Login failed");
        } finally {
            setLoading(false);
        }
    };


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
        
            setProductForm(prev => ({
                ...prev,
                [id]: value,
            }));
        
    };

    const manageAddProduct = async (e) => {
        e.preventDefault();
        setError("");
        setSuccessMessage("");

        const file = e.target.files?.[0];

        if (!productForm.productName || !productForm.price || !productForm.stock || !productForm.unit) {
            setError("Please fill in required fields.");
            return;
        }
        if (!userId) {
            setError("You must be logged in as supplier.");
            return;
        }

        const payload = {
            sku: productForm.productName.toLowerCase().replace(/\s+/g, "-"),
            name: productForm.productName,
            description: "",
            unit_code: productForm.unit,
            price: productForm.price,
            stock: productForm.stock,
            discount: productForm.discount || 0,
            delivery_time: null,
        };

        try {
            if (editingProductId) {
                await apiFetch(`/api/products/${editingProductId}/`, {
                    method: "PUT",
                    body: payload,
                    userId,
                });

                await loadProducts(userId);
                setSuccessMessage("Product updated successfully!");
                setEditingProductId(null);
            } else {
                await apiFetch("/api/products/", {
                    method: "POST",
                    body: payload,
                    userId,
                });

                await loadProducts(userId);
                setSuccessMessage("Product added successfully!");
            }


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

    const acceptRequest = async (id) => {
        if (
            !currentUser ||
            (currentUser.role !== "owner" && currentUser.role !== "manager")
        ) {
            setError("Not authorized");
            return;
        }

        try {
            await apiFetch(`/api/links/${id}/approve/`, { method: "POST" });
            await loadSupplierLinks(supplierId);
        } catch (err) {
            setError(err.message || "Failed to approve link");
        }
    };

    const rejectRequest = async (id) => {
        if (
            !currentUser ||
            (currentUser.role !== "owner" && currentUser.role !== "manager")
        ) {
            setError("Not authorized");
            return;
        }

        try {
            await apiFetch(`/api/links/${id}/reject/`, { method: "POST" });
            await loadSupplierLinks(supplierId);
        } catch (err) {
            setError(err.message || "Failed to reject link");
        }
    };

    const blockRequest = async (id) => {
        if (
            !currentUser ||
            (currentUser.role !== "owner" && currentUser.role !== "manager")
        ) {
            setError("Not authorized");
            return;
        }

        try {
            await apiFetch(`/api/links/${id}/reject/`, { method: "POST" });
            await loadSupplierLinks(supplierId);
        } catch (err) {
            setError(err.message || "Failed to block link");
        }
    };

    const createManager = async ({ name, email, password }) => {
        if (!currentUser || currentUser.role !== "owner") {
            setError("Only Owner can create Managers.");
            return;
        }
        if (!supplierId || !userId) {
            setError("User or supplier is not defined.");
            return;
        }
        if (!name || !email || !password) {
            setError("Fill manager fields.");
            return;
        }

        try {
            await apiFetch(`/api/suppliers/${supplierId}/staff/`, {
                method: "POST",
                body: {
                    full_name: name,
                    email,
                    password,
                    role_code: "manager",
                },
                userId,
            });

            await loadSupplierStaff(userId, supplierId);
            setMessage(`Manager '${name}' created.`);
            setTimeout(() => setMessage(""), 2000);
        } catch (err) {
            setError(err.message || "Failed to create manager");
        }
    };

    const createSales = async ({ name, email, password }) => {
        if (!currentUser || currentUser.role !== "owner") {
            setError("Only Owner can create Sales accounts.");
            return;
        }
        if (!supplierId || !userId) {
            setError("User or supplier is not defined.");
            return;
        }
        if (!name || !email || !password) {
            setError("Fill sales fields.");
            return;
        }

        try {
            await apiFetch(`/api/suppliers/${supplierId}/staff/`, {
                method: "POST",
                body: {
                    full_name: name,
                    email,
                    password,
                    role_code: "sales",
                },
                userId,
            });

            await loadSupplierStaff(userId, supplierId);
            setMessage(`Sales '${name}' created.`);
            setTimeout(() => setMessage(""), 2000);
        } catch (err) {
            setError(err.message || "Failed to create sales");
        }
    };


    const removeManager = (id) => {
        if (!currentUser || currentUser.role !== "owner") { setError("Only Owner can remove Managers."); return; }
        setUsers(prev => prev.filter(u => !(u.id === id && u.role === "manager")));
        setMessage("Manager removed.");
        setTimeout(() => setMessage(""), 2000);
    };

    const removeSales = (id) => {
        if (!currentUser || currentUser.role !== "owner") { setError("Only Owner can remove Sales."); return; }
        setUsers(prev => prev.filter(u => !(u.id === id && u.role === "sales")));
        setMessage("Sales rep removed.");
        setTimeout(() => setMessage(""), 2000);
    };

    const deleteSupplierAccount = () => {
        if (!currentUser || currentUser.role !== "owner") { setError("Only Owner can delete supplier account."); return; }
        setSupplierActive(false);
        setUsers([]);
        setProductList([]);
        setPendingRequests([]);
        setAcceptedRequests([]);
        setRejectedRequests([]);
        setBlockedRequests([]);
        setCurrentUser(null);
        setIsAuthenticated(false);
        setView("register");
        setMessage("Supplier account deactivated and data archived (local simulation).");
    };


    const acceptOrder = async (id) => {
        if (!userId) {
            setError("You must be logged in.");
            return;
        }

        try {
            await apiFetch(`/api/orders/${id}/accept/`, {
                method: "POST",
                userId,
            });
            await loadSupplierOrders(userId);
        } catch (err) {
            setError(err.message || "Failed to accept order");
        }
    };

    const rejectOrder = async (id) => {
        if (!userId) {
            setError("You must be logged in.");
            return;
        }

        try {
            await apiFetch(`/api/orders/${id}/reject/`, {
                method: "POST",
                userId,
            });
            await loadSupplierOrders(userId);
        } catch (err) {
            setError(err.message || "Failed to reject order");
        }
    };


    const resolveComplaint = async (id) => {
        if (!currentUser || currentUser.role !== "manager" && currentUser.role !== "owner") {
            setError("Not authorized");
            return;
        }

        try {
            await apiFetch(`/api/incidents/${id}/`, {
                method: "PATCH",
                userId,
                body: { status: "resolved" },
            });

            await loadComplaints(userId);
            setMessage("Complaint resolved!");
            setTimeout(() => setMessage(""), 2000);
        } catch (err) {
            setError(err.message || "Failed to resolve complaint");
        }
    };





    const isOwner = currentUser && currentUser.role === "owner";
    const isManager = currentUser && currentUser.role === "manager";
    const isSales = currentUser && currentUser.role === "sales";

    const goToUserManagement = async () => {
        if (!userId || !supplierId) {
            setError("User or supplier is not defined");
            return;
        }
        setError("");
        setMessage("");
        await loadSupplierStaff(userId, supplierId);
        setView("users");
    };

    const goToRequests = async () => {
        if (!supplierId) {
            setError("Supplier is not defined");
            return;
        }
        setError("");
        setMessage("");
        await loadSupplierLinks(supplierId);
        setView("requests");
    };
    const goToOrders = async () => {
        if (!userId) {
            setError("User is not defined");
            return;
        }
        setError("");
        setMessage("");
        await loadSupplierOrders(userId);
        setView("orders");
    };

    const goToComplaints = async () => {
        if (!userId) {
            setError("User is not defined");
            return;
        }
        setError("");
        setMessage("");
        await loadComplaints(userId);
        setView("complaints");
    }


    if (isAuthenticated && view === "requests") {
        if (!isOwner && !isManager) {

            setView("dashboard");
            setError("Only Owner and Manager can view requests.");
        } else {
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
    }

    // User management view: Owner only
    if (isAuthenticated && view === "users") {
        if (!isOwner) {
            setView("dashboard");
            setError("Only Owner can access User Management.");
        } else {
            const managers = users.filter(u => u.role === "manager");
            const sales = users.filter(u => u.role === "sales");
            return (
                <div className="min-h-screen bg-gray-700 p-8 flex justify-center">
                    <UserManagementView
                        managers={managers}
                        sales={sales}
                        createManager={createManager}
                        createSales={createSales}
                        removeManager={removeManager}
                        removeSales={removeSales}
                        setView={setView}
                        deleteSupplierAccount={deleteSupplierAccount}
                    />
                </div>
            );
        }
    }

    // Catalog dashboard: Owner & Manager can use;
    if (isAuthenticated && view === "dashboard") {
        // if supplier is inactive, redirect to registration
        if (!supplierActive) {
            setIsAuthenticated(false);
            setCurrentUser(null);
            setView("register");
            setMessage("Supplier account inactive.");
        } else {
            if (isManager || isOwner) {
                return (
                    <div className="min-h-screen bg-gray-700 p-8 flex justify-center">
                        <CatalogView
                            productForm={productForm}
                            manageAddProduct={manageAddProduct}
                            manageProductUpdate={manageProductUpdate}
                            productList={productList}
                            manageProductDelete={(id) => {
                                if (!isOwner && !isManager) { setError("Only Owner or Manager can delete products."); return; }
                                manageProductDelete(id);
                            }}
                            successMessage={successMessage}
                            editingProductId={editingProductId}
                            enterEditMode={(product) => {
                                if (!isOwner && !isManager) { setError("Only Owner or Manager can edit products."); return; }
                                enterEditMode(product);
                            }}

                            setView={setView}
                            setError={setError}
                            setMessage={setMessage}
                            setIsAuthenticated={setIsAuthenticated}
                            setCurrentUser={setCurrentUser}

                            isOwner={isOwner}
                            isManager={isManager}
                            goToUserManagement={goToUserManagement}
                            goToRequests={goToRequests}
                            goToOrders={goToOrders}
                            goToComplaints={goToComplaints}
                            error={error}
                        />
                    </div>
                );
            }

        }
    }

    if (isAuthenticated && view === "orders") {
        return (
            <div className="min-h-screen bg-gray-700 p-8 flex justify-center">
                <OrderView
                    pendingOrders={pendingOrders}
                    acceptedOrders={acceptedOrders}
                    rejectedOrders={rejectedOrders}
                    acceptOrder={acceptOrder}
                    rejectOrder={rejectOrder}
                    orderStatus={orderStatus}
                    setOrderStatus={setOrderStatus}
                    setView={setView}
                    setError={setError}
                    setMessage={setMessage}
                    isOwner={isOwner}
                    isManager={isManager}
                    productList={productList}
                />
            </div>
        );
    }

    if (isAuthenticated && view === "complaints") {
        return (
            <div>
                <ComplaintsView
                    escalatedComplaints={escalatedComplaints}
                    resolvedComplaints={resolvedComplaints}
                    complaintViewType={complaintViewType}
                    setComplaintViewType={setComplaintViewType}
                    setView={setView}
                    isOwner={isOwner}
                    isManager={isManager}
                    resolveComplaint={resolveComplaint}
                />
            </div>
        )
    }


    if (!isAuthenticated) {
        return (
            <div className="min-h-screen bg-gray-700 flex items-center justify-center p-4">
                <div className="bg-white p-6 w-full max-w-sm border border-gray-400 shadow-xl space-y-4">
                    {error && (
                        <div className="bg-red-100 text-red-700 p-3 mb-4 border border-red-500 text-sm font-medium">{error}</div>
                    )}
                    {message && !error && (
                        <div className="bg-green-100 text-green-700 p-3 mb-4 border border-green-500 text-sm font-medium">{message}</div>
                    )}

                    {view === "register" ? (
                        <RegistrationForm formData={formData} manageChange={manageChange} manageRegistrationSubmit={manageRegistrationSubmit} loading={loading} />
                    ) : (
                        <LoginForm formData={formData} manageChange={manageChange} manageLoginSubmit={manageLoginSubmit} loading={loading} />
                    )}

                    <div className="text-center text-gray-700 text-sm pt-2">
                        {view === "register" ? (
                            <>
                                Already have an account?{" "}
                                <button onClick={() => { setView("login"); setError(""); setMessage(""); }} className="text-gray-700 hover:underline font-medium">Login here</button>
                            </>
                        ) : (
                            <>
                                Need a supplier account?{" "}
                                <button onClick={() => { setView("register"); setError(""); setMessage(""); }} className="text-gray-700 hover:underline font-medium">Register here</button>
                            </>
                        )}
                    </div>
                </div>
            </div>
        );
    }
};

export default App;
