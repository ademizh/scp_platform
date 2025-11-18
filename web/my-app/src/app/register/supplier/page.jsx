"use client";

import React, { useState } from 'react';
import { UserPlus, Loader, Building2 } from "lucide-react";

const RegistrationForm = ({ formData, manageChange, manageRegistrationSubmit, loading }) => (

    <form onSubmit={manageRegistrationSubmit}>
        {/* Conditional Error Message */}
        {/* {error && (
            <div className="bg-red-100 border-l-4 border-red-500 text-red-700 p-3 rounded mb-4" role="alert">
                <p className="font-semibold">Registration Error</p>
                <p className="text-sm">{error}</p>
            </div>
        )} */}

        {/* Supplier Name */}
        <div className="mb-4">
            <label htmlFor="supplierName" className="block font-medium text-gray-700 mb-1">
                Supplier Name
            </label>
            <input
                id="supplierName"
                type="text"
                className="w-full border border-gray-300 rounded-lg p-2 text-gray-900"
                onChange={manageChange}
                value={formData.supplierName}
            />
        </div>

        {/* Email */}
        <div className="mb-4">
            <label htmlFor="email" className="block font-medium text-gray-700 mb-1">
                Email Address
            </label>
            <input
                id="email"
                type="email"
                className="w-full border border-gray-300 rounded-lg p-2 text-gray-900"
                onChange={manageChange}
                value={formData.email}
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

        {/* Submission Button */}
        <button
            type="submit"
            disabled={loading}
            className="w-full flex items-center justify-center bg-gray-700 text-white font-bold py-3 rounded-xl hover:bg-gray-500 transition duration-200 disabled:bg-gray-300"
        >
            {loading ? (
                <>
                    <Loader className="animate-spin h-5 w-5 mr-3" />
                    Processing Registration...
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
                {/* <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Mail className="h-5 w-5 text-gray-400" />
                </div> */}
                <input
                    type="email"
                    id="email"
                    value={formData.email}
                    onChange={manageChange}
                    className="block w-full pl-4 pr-4 py-2 text-gray-900 border border-gray-300 rounded-lg focus:ring-indigo-500 focus:border-indigo-500 transition duration-150"
                    placeholder="supplier@company.com"
                    required
                />
            </div>
        </div>

        {/* Password Field */}
        <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">Password</label>
            <div className="mt-1 relative rounded-lg shadow-sm">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    {/* <Lock className="h-5 w-5 text-gray-400" /> */}
                </div>
                <input
                    type="password"
                    id="password"
                    value={formData.password}
                    onChange={manageChange}
                    className="block w-full pl-4 pr-4 py-2 text-gray-900 border border-gray-300 rounded-lg focus:ring-indigo-500 focus:border-indigo-500 transition duration-150"
                    placeholder="••••••••"
                    required
                />
            </div>
        </div>

        {/* Submission Button */}
        <button
            type="submit"
            disabled={loading}
            className="w-full flex items-center justify-center bg-green-600 text-white font-bold py-3 rounded-xl tracking-wide hover:bg-green-700 transition duration-200 disabled:bg-green-400 disabled:cursor-not-allowed shadow-lg mt-6"
        >
            {loading ? (
                <>
                    <Loader className="animate-spin h-5 w-5 mr-3" />
                    Logging In...
                </>
            ) : (
                <>
                    {/* <LogIn className="h-5 w-5 mr-2" /> */}
                    Log In to SCP
                </>
            )}
        </button>
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
        const { id, value } = e.target; // what triggered event
        setFormData(prevFormData => ({
            ...prevFormData,
            [id]: value
        }));
        setError(null); // clear out the errors
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
    }

    const manageRegistrationSubmit = async (e) => {
        e.preventDefault();

        if (!verifyForm()) {
            return;
        }

        setLoading(true);
        setError(''); // clear out the errors

        // simulates api use
        try {
            await new Promise((resolve) => {
                // const delay = Math.floor(Math.random() * 4500) + 500;
                setTimeout(() => {
                    resolve("Connection successful.");
                }, 3000)
                // setTimeout(() => {
                //     if (delay > 3000) {
                //         reject("Connection timeout.");
                //     } else {
                //         resolve("Connection successful.");
                //     }
                // }, delay)
            })
            setIsRegistered(true);
            // console.log("Registartion successful.")

            setFormData(prevFormData => ({
                supplierName: '',
                email: prevFormData.email,
                password: '',
                confirmPassword: '',
            }));

            setTimeout(() => {
                setMessage("Registartion successful! You can log in.")
                setView('login');
            }, 2000);


        } catch (e) {
            console.error("Error during registration:", e);
            setError("Registartion failed. Please try again.");
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
        setError(null);

        try {
            await new Promise((resolve) => {
                // const delay = Math.floor(Math.random() * 4500) + 500;
                setTimeout(() => {
                    resolve("Connection successful.")
                }, 3000);
                // setTimeout(() => {
                //     if (delay > 3000) {
                //         reject("Connection timeout.");
                //     } else {
                //         resolve("Connection successful.");
                //     }
                // }, delay)
            })

            // check if account exists, password correct
            setMessage("Login successful!")
            console.log("Login succesful!");
            // go to supplier page
        } catch (e) {
            console.error("Error during login:", e);
            setError("Login failed. Check your credentials.");
        } finally {
            setLoading(false);
        }
    }

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
                            setIsRegistered(false),
                                setView("login")
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

                {/* Conditional Message Area */}
                {error && (
                    <div className="bg-red-100 border-l-4 border-red-500 text-red-700 p-3 rounded-lg mb-4" role="alert">
                        <p className="font-semibold">Error</p>
                        <p className="text-sm">{error}</p>
                    </div>
                )}

                {/* {successMessage && (
          <div className="bg-green-100 border-l-4 border-green-500 text-green-700 p-3 rounded-lg mb-4 flex items-center" role="status">
            <CheckCircle className="h-5 w-5 mr-2 flex-shrink-0" />
            <p className="text-sm font-medium">{successMessage}</p>
          </div>
        )} */}


                {/* Conditional Form Rendering */}
                {/* Now we pass props to the stable components */}
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

                {/* Footer Navigation*/}
                <p className="text-center text-sm text-gray-500 mt-6 pt-4 border-t">
                    {view === 'register' ? (
                        <>
                            Already have an account?
                            <button
                                onClick={() => { setView('login'); setFormData({ email: '', password: '' }); setError(''); }}
                                className="font-medium text-green-600 hover:text-green-500 ml-1 transition duration-150"
                            >
                                Log In
                            </button>
                        </>
                    ) : (
                        <>
                            New supplier?
                            <button
                                onClick={() => { setView('register'); setFormData({ email: '', password: '', supplierName: '', confirmPassword: '' }); setError(''); }}
                                className="font-medium text-indigo-600 hover:text-indigo-500 ml-1 transition duration-150"
                            >
                                Register here
                            </button>
                        </>
                    )}
                </p>
            </div>
        </div>
    );


};


export default App;


