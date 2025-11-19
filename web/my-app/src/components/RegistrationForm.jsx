"use client";

import { Building2, UserPlus, Loader } from "lucide-react";

export default function RegistrationForm({ formData, onChange, onSubmit, loading }) {
    return (
        <form onSubmit={onSubmit}>

            {/* Supplier Name */}
            <div className="mb-4">
                <label className="block font-medium text-gray-700 mb-1">
                    Supplier / Company Name
                </label>
                <div className="flex items-center border border-gray-300 rounded-lg px-3 py-2">
                    <Building2 className="text-gray-400 mr-2" />
                    <input
                        id="supplierName"
                        type="text"
                        value={formData.supplierName}
                        onChange={onChange}
                        placeholder="Fresh Foods Ltd."
                        className="w-full outline-none text-gray-900"
                        required
                    />
                </div>
            </div>

            {/* Email */}
            <div className="mb-4">
                <label className="block font-medium text-gray-700 mb-1">Business Email</label>
                <input
                    id="email"
                    type="email"
                    value={formData.email}
                    onChange={onChange}
                    placeholder="supplier@example.com"
                    className="w-full border border-gray-300 rounded-lg p-2 text-gray-900"
                    required
                />
            </div>

            {/* Password */}
            <div className="mb-4">
                <label className="block font-medium text-gray-700 mb-1">Password</label>
                <input
                    id="password"
                    type="password"
                    value={formData.password}
                    onChange={onChange}
                    placeholder="••••••••"
                    className="w-full border border-gray-300 rounded-lg p-2 text-gray-900"
                    required
                />
            </div>

            {/* Confirm Password */}
            <div className="mb-6">
                <label className="block font-medium text-gray-700 mb-1">
                    Confirm Password
                </label>
                <input
                    id="confirmPassword"
                    type="password"
                    value={formData.confirmPassword}
                    onChange={onChange}
                    placeholder="••••••••"
                    className="w-full border border-gray-300 rounded-lg p-2 text-gray-900"
                    required
                />
            </div>

            {/* Submit */}
            <button
                type="submit"
                disabled={loading}
                className="w-full bg-gray-700 text-white py-2 px-4 rounded-xl flex items-center justify-center hover:bg-gray-600 transition-colors"
            >
                {loading ? (
                    <>
                        <Loader className="h-5 w-5 mr-2 animate-spin" />
                        Processing...
                    </>
                ) : (
                    <>
                        <UserPlus className="h-5 w-5 mr-2" />
                        Register Supplier Account
                    </>
                )}
            </button>
        </form>
    );
}
