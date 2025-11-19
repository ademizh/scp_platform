"use client";

export default function CatalogView({
    productForm,
    onUpdateProduct,
    onAddProduct,
    products,
    loading, // ADDED FOR DB
}) {
    return (
        <div className="max-w-3xl mx-auto py-6 text-gray-900">
            <h1 className="text-3xl font-bold mb-6">Catalog</h1>

            {/* Product Form */}
            <form onSubmit={onAddProduct} className="grid grid-cols-2 gap-4 mb-8">
                <div className="col-span-2">
                    <label>Product Name</label>
                    <input
                        id="productName"
                        value={productForm.productName}
                        onChange={onUpdateProduct}
                        className="w-full border p-2 rounded"
                        required
                    />
                </div>

                <div>
                    <label>Price</label>
                    <input
                        id="price"
                        type="number"
                        step="0.01"
                        value={productForm.price}
                        onChange={onUpdateProduct}
                        className="w-full border p-2 rounded"
                        required
                    />
                </div>

                <div>
                    <label>Discount (%)</label>
                    <input
                        id="discount"
                        type="number"
                        value={productForm.discount}
                        onChange={onUpdateProduct}
                        className="w-full border p-2 rounded"
                    />
                </div>

                <div>
                    <label>Stock</label>
                    <input
                        id="stock"
                        type="number"
                        value={productForm.stock}
                        onChange={onUpdateProduct}
                        className="w-full border p-2 rounded"
                        required
                    />
                </div>

                <div>
                    <label>Unit</label>
                    <input
                        id="unit"
                        value={productForm.unit}
                        onChange={onUpdateProduct}
                        className="w-full border p-2 rounded"
                        required
                    />
                </div>

                <button
                    type="submit"
                    disabled={loading} // ADDED FOR DB
                    className="col-span-2 bg-gray-800 text-white py-2 rounded hover:bg-gray-700"
                >
                    {loading ? "Saving..." : "Add Product"} {/* ADDED FOR DB */}
                </button>
            </form>

            {/* Product Table */}
            <table className="w-full border">
                <thead>
                    <tr className="bg-gray-200">
                        <th className="p-2 border">Name</th>
                        <th className="p-2 border">Price</th>
                        <th className="p-2 border">Discount</th>
                        <th className="p-2 border">Stock</th>
                        <th className="p-2 border">Unit</th>
                    </tr>
                </thead>

                <tbody>
                    {products.map((p) => (
                        <tr key={p.id} className="border">
                            <td className="p-2 border">{p.productName}</td>
                            <td className="p-2 border">{p.price}</td>
                            <td className="p-2 border">{p.discount}</td>
                            <td className="p-2 border">{p.stock}</td>
                            <td className="p-2 border">{p.unit}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
}
