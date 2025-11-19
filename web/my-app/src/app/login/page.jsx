"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import LoginForm from "@/components/LoginForm";
import { API_BASE_URL } from "@/lib/api";

export default function LoginPage({ onRegisterClick, setUser }) {
    const router = useRouter();

    const [formData, setFormData] = useState({
        email: "",
        password: "",
    });

    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");

    const onChange = (e) => {
        const { id, value } = e.target;
        setFormData((prev) => ({ ...prev, [id]: value }));
        setError("");
    };

    const manageLogin = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError("");

        try {
            const res = await fetch(`${API_BASE_URL}/api/auth/login/`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    email: formData.email.trim(),
                    password: formData.password,
                    login_as: "supplier",
                }),
            });

            if (!res.ok) {
                const data = await res.json().catch(() => null);
                throw new Error(data?.detail || "Invalid login credentials.");
            }

            const data = await res.json();
            localStorage.setItem("scp_user", JSON.stringify(data));
            setUser(data);

            router.push("/catalog");

        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-gray-700 flex items-center justify-center p-6">
            <div className="bg-white p-8 rounded-xl shadow-lg w-full max-w-md">

                <h1 className="text-2xl font-bold mb-6 text-gray-900">Supplier Login</h1>

                {error && (
                    <div className="bg-red-100 text-red-700 p-3 rounded mb-4">
                        {error}
                    </div>
                )}

                <LoginForm
                    formData={formData}
                    onChange={onChange}
                    onSubmit={manageLogin}
                    loading={loading}
                />

                <p className="mt-4 text-center text-sm text-gray-700">
                    Don't have an account?{" "}
                    <span
                        onClick={() => router.push("/register")}
                        className="text-blue-600 cursor-pointer hover:underline"
                    >
                        Register here
                    </span>
                </p>
            </div>
        </div>
    );
}
