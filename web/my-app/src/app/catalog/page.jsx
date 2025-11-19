"use client";

import { useState, useEffect } from "react";
import CatalogView from "@/components/CatalogView";
import { API_BASE_URL } from "@/lib/api";

export default function CatalogPage({ user }) {
    const [products, setProducts] = useState([]);
    const [loading, setLoading] = useState(false); // ADDED FOR DB

    const [productForm, setProductForm] = useState({
        productName: "",
        price: "",
        discount: "",
        stock: "",
        unit: "",
    });

    const fetchProducts = async () => { // ADDED FOR DB
        try {
            setLoading(true);
            // const res = await fetch(`${API_BASE_URL}/api/products/`, {
            //     headers: { "Authorization": `Bearer ${user.token}` } // ADDED FOR DB auth
            // });

            const res = await fetch(`${API_BASE_URL}/api/products/`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${user.token}`,
                },
                body: JSON.stringify(newProduct),
            });

            if (!res.ok) throw new Error("Failed to fetch products");
            const data = await res.json();
            setProducts(data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { fetchProducts(); }, []); // ADDED FOR DB

    const onUpdateProduct = (e) => {
        const { id, value } = e.target;
        setProductForm((prev) => ({ ...prev, [id]: value }));
    };

    const onAddProduct = async (e) => {
        e.preventDefault();

        const newProduct = {
            id: Date.now(),
            productName: productForm.productName,
            price: parseFloat(productForm.price),
            discount: parseInt(productForm.discount || 0),
            stock: parseInt(productForm.stock),
            unit: productForm.unit,
        };

        try { // ADDED FOR DB
            setLoading(true);
            const res = await fetch(`${API_BASE_URL}/api/products/`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${user.token}` // ADDED FOR DB auth
                },
                body: JSON.stringify(newProduct),
            });
            if (!res.ok) throw new Error("Failed to save product");
            const savedProduct = await res.json();
            setProducts((prev) => [...prev, savedProduct]);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
            setProductForm({ productName: "", price: "", discount: "", stock: "", unit: "" });
        }

        // setProducts((prev) => [...prev, newProduct]);

        // setProductForm({
        //     productName: "",
        //     price: "",
        //     discount: "",
        //     stock: "",
        //     unit: "",
        // });
    };

    return (
        <div className="min-h-screen bg-gray-100 p-6">
            <CatalogView
                productForm={productForm}
                onUpdateProduct={onUpdateProduct}
                onAddProduct={onAddProduct}
                products={products}
                loading={loading} // ADDED FOR DB
            />
        </div>
    );
}
