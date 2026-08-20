import React, { useState } from 'react';
import { register as apiRegister } from '../api';

interface Props {
	onRegister: (user: any) => void;
	onBackToLogin: () => void;
}

const ROLES = [
	{ value: 'CITIZEN', label: 'Citizen / Reporter' },
	{ value: 'NGO', label: 'NGO / Organisation' },
	{ value: 'VET', label: 'Veterinarian' },
];

export const RegisterPage: React.FC<Props> = ({ onRegister, onBackToLogin }) => {
	const [name, setName] = useState('');
	const [email, setEmail] = useState('');
	const [password, setPassword] = useState('');
	const [role, setRole] = useState('CITIZEN');
	const [loading, setLoading] = useState(false);
	const [error, setError] = useState('');

	const submit = async (event: React.FormEvent) => {
		event.preventDefault();
		setLoading(true);
		setError('');
		try {
			const response = await apiRegister({ name, email, password, role });
			onRegister(response);
		} catch (err: any) {
			setError(err.message || 'Registration failed');
		} finally {
			setLoading(false);
		}
	};

	return (
		<div className="max-w-md mx-auto mt-12 bg-white rounded-xl shadow-md p-8">
			<div className="text-center mb-6">
				<div className="text-4xl mb-2">🐾</div>
				<h2 className="text-2xl font-bold text-teal-800 font-adlam">Create your Karuṇā account</h2>
			</div>
			<form onSubmit={submit} className="space-y-4">
				<div>
					<label htmlFor="citizen-register-name" className="block text-sm font-medium text-slate-700 mb-1">Name</label>
					<input id="citizen-register-name" required value={name} onChange={(e) => setName(e.target.value)} placeholder="Full name"
						className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-teal-500" />
				</div>
				<div>
					<label htmlFor="citizen-register-email" className="block text-sm font-medium text-slate-700 mb-1">Email</label>
					<input id="citizen-register-email" type="email" required value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com"
						className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-teal-500" />
				</div>
				<div>
					<label htmlFor="citizen-register-password" className="block text-sm font-medium text-slate-700 mb-1">Password</label>
					<input id="citizen-register-password" type="password" required value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Create a password"
						className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-teal-500" />
				</div>
				<div>
					<label htmlFor="citizen-register-role" className="block text-sm font-medium text-slate-700 mb-1">Account type</label>
					<select id="citizen-register-role" value={role} onChange={(e) => setRole(e.target.value)}
						className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-teal-500">
						{ROLES.map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}
					</select>
				</div>
				{error && <div className="text-red-600 text-sm bg-red-50 p-3 rounded-lg">{error}</div>}
				<button type="submit" disabled={loading} className="w-full bg-teal-600 text-white font-bold py-3 rounded-lg hover:bg-teal-700 disabled:opacity-50">
					{loading ? 'Creating account...' : 'Create account'}
				</button>
			</form>
			<button onClick={onBackToLogin} className="mt-4 w-full text-sm text-teal-700 hover:underline">
				Back to sign in
			</button>
		</div>
	);
};