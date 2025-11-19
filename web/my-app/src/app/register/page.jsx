"use client";

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import RegistrationForm from "@/components/RegistrationForm";
import { API_BASE_URL } from "@/lib/api";

// import { UserPlus, Loader, Building2 } from "lucide-react";


export default function RegisterPage({ onLoginClick, setUser }) {
    const router = useRouter();

    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const [message, setMessage] = useState("");

    const [formData, setFormData] = useState({
        supplierName: "",
        email: "",
        password: "",
        confirmPassword: "",
    });

    const onChange = (e) => {
        const { id, value } = e.target;
        setFormData((prev) => ({ ...prev, [id]: value }));
        setError("");
    };

    const manageRegister = async (e) => {
        e.preventDefault();
        setError("");
        setLoading(true);

        if (formData.password !== formData.confirmPassword) {
            setError("Passwords do not match.");
            setLoading(false);
            return;
        }

        try {
            const res = await fetch(`${API_BASE_URL}/api/auth/register-supplier/`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    full_name: formData.supplierName,
                    supplier_name: formData.supplierName,
                    email: formData.email.trim(),
                    password: formData.password,
                }),
            });

            if (!res.ok) {
                const data = await res.json().catch(() => null);
                throw new Error(data?.detail || "Registration failed.");
            }

            const data = await res.json(); // ADDED FOR APP PAGE CONTROL
            localStorage.setItem("scp_user", JSON.stringify(data)); // ADDED FOR APP PAGE CONTROL
            setUser(data); // ADDED FOR APP PAGE CONTROL

            setMessage("Registration successful! Redirecting...");
            setTimeout(() => router.push("/login"), 1500);

        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-gray-700 flex items-center justify-center p-6">
            <div className="bg-white p-8 rounded-xl shadow-lg w-full max-w-md">

                <h1 className="text-2xl font-bold mb-6 text-gray-900">
                    Supplier Registration
                </h1>

                {error && (
                    <div className="bg-red-100 text-red-700 p-3 rounded mb-4">
                        {error}
                    </div>
                )}

                {message && (
                    <div className="bg-green-100 text-green-700 p-3 rounded mb-4">
                        {message}
                    </div>
                )}

                <RegistrationForm
                    formData={formData}
                    loading={loading}
                    onChange={onChange}
                    onSubmit={manageRegister}
                />

                <p className="mt-4 text-center text-sm text-gray-700">
                    Already have an account?{" "}
                    <span
                        onClick={() => router.push("/login")}
                        className="text-blue-600 cursor-pointer hover:underline"
                    >
                        Login here
                    </span>
                </p>
            </div>
        </div>
    );
}



