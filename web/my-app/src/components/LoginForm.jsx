"use client";

import { Loader } from "lucide-react";

export default function LoginForm({ formData, onChange, onSubmit, loading }) {
    return (
        <form onSubmit={onSubmit} className="space-y-4">

            {/* Email */}
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
                <input
                    id="email"
                    type="email"
                    value={formData.email}
                    onChange={onChange}
                    placeholder="supplier@company.com"
                    className="w-full border border-gray-300 rounded-lg p-2"
                    required
                />
            </div>

            {/* Password */}
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
                <input
                    id="password"
                    type="password"
                    value={formData.password}
                    onChange={onChange}
                    placeholder="Enter your password"
                    className="w-full border border-gray-300 rounded-lg p-2"
                    required
                />
            </div>

            {/* Submit */}
            <button
                type="submit"
                disabled={loading}
                className="w-full bg-gray-700 text-white px-4 py-2 rounded-xl flex justify-center hover:bg-gray-600 transition-colors"
            >
                {loading ? (
                    <>
                        <Loader className="h-5 w-5 mr-2 animate-spin" />
                        Signing in...
                    </>
                ) : (
                    "Sign in as Supplier"
                )}
            </button>
        </form>
    );
}
