"use client";

import React, { useState } from 'react';
import { UserPlus, Loader, Building2 } from "lucide-react";

// Base URL of your Django backend – same as in Flutter ApiClient
const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://127.0.0.1:8000';

const RegistrationForm = ({ formData, manageChange, manageRegistrationSubmit, loading }) => (

    <form onSubmit={manageRegistrationSubmit}>
        {/* Supplier Name */}
        <div className="mb-4">
            <label htmlFor="supplierName" className="block font-medium text-gray-700 mb-1">
                Supplier/Company Name
            </label>
            <div className="flex items-center border border-gray-300 rounded-lg px-3 py-2">
                <Building2 className="text-gray-400 mr-2" />
                <input
                    id="supplierName"
                    type="text"
                    className="w-full outline-none text-gray-900"
                    onChange={manageChange}
                    value={formData.supplierName}
                    placeholder="Example: Fresh Foods Ltd."
                    required
                />
            </div>
        </div>

        {/* Email */}
        <div className="mb-4">
            <label htmlFor="email" className="block font-medium text-gray-700 mb-1">
                Business Email
            </label>
            <input
                id="email"
                type="email"
                className="w-full border border-gray-300 rounded-lg p-2 text-gray-900"
                onChange={manageChange}
                value={formData.email}
                placeholder="supplier@example.com"
                required
            />
        </div>

        {/* Password */}
        <div className="mb-4">
            <label htmlFor="password" className="block font-medium text-gray-700 mb-1">
                Password
            </label>
            <input
                id="password"
                type="password"
                className="w-full border border-gray-300 rounded-lg p-2 text-gray-900"
                onChange={manageChange}
                value={formData.password}
                placeholder="••••••••"
                required
            />
        </div>

        {/* Confirm Password */}
        <div className="mb-6">
            <label htmlFor="confirmPassword" className="block font-medium text-gray-700 mb-1">
                Confirm Password
            </label>
            <input
                id="confirmPassword"
                type="password"
                className="w-full border border-gray-300 rounded-lg p-2 text-gray-900"
                onChange={manageChange}
                value={formData.confirmPassword}
                placeholder="••••••••"
                required
            />
        </div>

        {/* Submit Button */}
        <button
            type="submit"
            className="w-full flex items-center justify-center bg-gray-700 text-white py-2 px-4 rounded-xl hover:bg-gray-500 transition duration-200"
            disabled={loading}
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

const LoginForm = ({ formData, manageChange, manageLoginSubmit, loading }) => (
    <form onSubmit={manageLoginSubmit} className="space-y-4">
        {/* Email Field */}
        <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
            <div className="mt-1 relative rounded-lg shadow-sm">
                <input
                    type="email"
                    id="email"
                    value={formData.email}
                    onChange={manageChange}
                    className="block w-full pl-4 pr-4 py-2 text-gray-900 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition duration-150"
                    placeholder="supplier@company.com"
                    required
                />
            </div>
        </div>

        {/* Password Field */}
        <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">Password</label>
            <div className="mt-1 relative rounded-lg shadow-sm">
                <input
                    type="password"
                    id="password"
                    value={formData.password}
                    onChange={manageChange}
                    className="block w-full pl-4 pr-10 py-2 text-gray-900 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition duration-150"
                    placeholder="Enter your password"
                    required
                />
            </div>
        </div>

        {/* Submit Button */}
        <div className="pt-2">
            <button
                type="submit"
                className="w-full inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-xl shadow-sm text-white bg-gray-700 hover:bg-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-600 transition duration-150"
                disabled={loading}
            >
                {loading ? (
                    <>
                        <Loader className="animate-spin h-5 w-5 mr-2" />
                        Signing in...
                    </>
                ) : (
                    "Sign in as Supplier"
                )}
            </button>
        </div>
    </form>
);

const App = () => {
    const [view, setView] = useState('register');
    const [formData, setFormData] = useState({
        supplierName: '',
        email: '',
        password: '',
        confirmPassword: '',
    });
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const [isRegistered, setIsRegistered] = useState(false);
    const [message, setMessage] = useState('');

    const manageChange = (e) => {
        const { id, value } = e.target;
        setFormData(prevFormData => ({
            ...prevFormData,
            [id]: value
        }));
        setError('');
    };

    const verifyForm = () => {
        if (!formData.supplierName || !formData.email || !formData.password || !formData.confirmPassword) {
            setError("Please fill in all fields.");
            return false;
        }
        const validEmail = /^[ ]*([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})[ ]*$/i;
        if (!validEmail.test(formData.email)) {
            setError("Please enter a valid email.");
            return false;
        }
        if (formData.password.length < 8) {
            setError("Password must have at least 8 characters.");
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
        const validEmail = /^[ ]*([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})[ ]*$/i;
        if (!validEmail.test(formData.email)) {
            setError("Please enter a valid email.");
            return false;
        }
        return true;
    };

    const manageRegistrationSubmit = async (e) => {
        e.preventDefault();

        if (!verifyForm()) {
            return;
        }

        setLoading(true);
        setError('');
        setMessage('');

        try {
            const response = await fetch(`${API_BASE_URL}/api/auth/register-supplier/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    email: formData.email.trim(),
                    password: formData.password,
                    // сейчас full_name = supplierName; позже можно добавить отдельное поле
                    full_name: formData.supplierName.trim(),
                    supplier_name: formData.supplierName.trim(),
                }),
            });

            if (!response.ok) {
                let detail = 'Registration failed. Please try again.';
                try {
                    const data = await response.json();
                    if (data.detail) {
                        detail = data.detail;
                    } else if (typeof data === 'object') {
                        detail = JSON.stringify(data);
                    }
                } catch { }
                throw new Error(detail);
            }

            const data = await response.json();

            // опционально сохраняем сессию
            try {
                localStorage.setItem('scp_user', JSON.stringify(data));
            } catch { }

            setIsRegistered(true);
            setFormData(prevFormData => ({
                ...prevFormData,
                supplierName: '',
                password: '',
                confirmPassword: '',
            }));

            setMessage('Registration successful! You can log in.');
            setView('login');
        } catch (err) {
            console.error('Error during registration:', err);
            setError(err.message || 'Registration failed. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    const manageLoginSubmit = async (e) => {
        e.preventDefault();

        if (!verifyLoginForm()) {
            return;
        }

        setLoading(true);
        setError('');
        setMessage('');

        try {
            const response = await fetch(`${API_BASE_URL}/api/auth/login/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    email: formData.email.trim(),
                    password: formData.password,
                    login_as: 'supplier',
                }),
            });

            if (!response.ok) {
                let detail = 'Login failed. Check your credentials.';
                try {
                    const data = await response.json();
                    if (data.detail) {
                        detail = data.detail;
                    } else if (typeof data === 'object') {
                        detail = JSON.stringify(data);
                    }
                } catch { }
                throw new Error(detail);
            }

            const data = await response.json();

            try {
                localStorage.setItem('scp_user', JSON.stringify(data));
            } catch { }

            setMessage('Login successful!');
            console.log('Login successful!', data);
            // TODO: потом можно сделать router.push('/supplier-dashboard')
        } catch (err) {
            console.error('Error during login:', err);
            setError(err.message || 'Login failed. Check your credentials.');
        } finally {
            setLoading(false);
        }
    };

    if (isRegistered) {
        return (
            <div className="min-h-screen bg-gray-700 flex items-center justify-center p-4">
                <div className="bg-white p-8 rounded-2xl shadow-2xl max-w-md w-full text-center">
                    <UserPlus className="h-12 w-12 text-green-600 mx-auto mb-4" />
                    <h2 className="text-3xl font-bold text-gray-800 mb-2">Registration Successful!</h2>
                    <p className="text-gray-600 mb-6">
                        Thank you, your supplier account has been registered.
                    </p>
                    <button
                        onClick={() => {
                            setIsRegistered(false);
                            setView('login');
                        }}
                        className="w-full bg-gray-700 text-white py-2 px-4 rounded-xl hover:bg-gray-500 transition duration-200"
                    >
                        Go to Login
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gray-700 flex items-center justify-center p-4 font-inter">
            <div className="bg-white p-6 sm:p-8 rounded-2xl shadow-2xl max-w-lg w-full transform transition duration-500 hover:shadow-3xl border-t-4">
                {/* Header */}
                <div className="flex items-center space-x-3 mb-6 border-b pb-4">
                    <h1 className="text-3xl font-extrabold text-gray-900">
                        {view === 'register' ? 'Supplier Registration' : 'Supplier Login'}
                    </h1>
                </div>

                {/* Error */}
                {error && (
                    <div className="bg-red-100 border-l-4 border-red-500 text-red-700 p-3 rounded-lg mb-4" role="alert">
                        <p className="font-semibold">Error</p>
                        <p className="text-sm">{error}</p>
                    </div>
                )}

                {/* Success */}
                {message && !error && (
                    <div className="bg-green-100 border-l-4 border-green-500 text-green-700 p-3 rounded-lg mb-4" role="status">
                        <p className="text-sm">{message}</p>
                    </div>
                )}

                {/* Forms */}
                {view === 'register' ? (
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

                {/* Switch link */}
                <div className="mt-6 text-center text-sm text-gray-600">
                    <p>
                        {view === 'register' ? (
                            <>
                                Already have an account?{' '}
                                <button
                                    onClick={() => {
                                        setView('login');
                                        setError('');
                                        setMessage('');
                                    }}
                                    className="text-gray-800 font-medium hover:underline"
                                >
                                    Login here
                                </button>
                            </>
                        ) : (
                            <>
                                Need a supplier account?{' '}
                                <button
                                    onClick={() => {
                                        setView('register');
                                        setError('');
                                        setMessage('');
                                    }}
                                    className="text-gray-800 font-medium hover:underline"
                                >
                                    Register here
                                </button>
                            </>
                        )}
                    </p>
                </div>
            </div>
        </div>
    );
};

export default App;
