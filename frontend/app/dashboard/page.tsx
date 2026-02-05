'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import api from '@/lib/api';
import { useAuthStore } from '@/store/authStore';

interface Service {
  id: string;
  name: string;
  description: string;
  enabled: boolean;
  link: string;
}

export default function Dashboard() {
  const router = useRouter();
  const { user, token, logout } = useAuthStore();
  const [services, setServices] = useState<Service[]>([]);
  const [loading, setLoading] = useState(true);

  // Profile Edit State
  const [profile, setProfile] = useState({
    name: user?.name || '',
    image: user?.image || ''
  });
  const [isEditing, setIsEditing] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (!token) {
      router.push('/login');
      return; 
    }

    const fetchData = async () => {
      try {
        const servicesRes = await api.get('/services');
        setServices(servicesRes.data);
      } catch (err) {
        console.error("Failed to fetch services", err);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [token, router]);

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  const toggleService = (id: string) => {
    // Logic to toggle service locally (for demo)
    setServices(services.map(s => s.id === id ? { ...s, enabled: !s.enabled } : s));
  };
  
  const handleUpdateProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
        const res = await api.put('/users/me', profile);
        // update user in store
        // useAuthStore.setState({ user: res.data }); // simplistic update
        // We should ideally use setAuth but need token... reuse current token
        useAuthStore.getState().setAuth(res.data, token!); 
        setMessage("Profile updated successfully");
        setIsEditing(false);
    } catch (err) {
        setMessage("Failed to update profile");
    }
  }

  if (loading) return <div className="p-24 text-center">Loading...</div>;

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
        <nav className="bg-white dark:bg-gray-800 shadow">
            <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                <div className="flex h-16 justify-between">
                    <div className="flex">
                        <div className="flex flex-shrink-0 items-center gap-4">
                            <h1 className="text-xl font-bold text-indigo-600 dark:text-indigo-400">SAuthenServer Dashboard</h1>
                            {user?.email === 'root@skoservice.com' && (
                                <Link href="/admin/dashboard" className="px-3 py-1 bg-red-600 text-white rounded text-xs font-bold hover:bg-red-700">
                                    ROOT ADMIN
                                </Link>
                            )}
                        </div>
                    </div>
                    <div className="flex items-center">
                        <span className="mr-4 text-sm text-gray-500 dark:text-gray-300">Welcome, {user?.name}</span>
                        <button
                            onClick={handleLogout}
                            className="rounded-md bg-gray-100 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-200 dark:hover:bg-gray-600"
                        >
                            Logout
                        </button>
                    </div>
                </div>
            </div>
        </nav>

        <main className="mx-auto max-w-7xl py-6 sm:px-6 lg:px-8">
            <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
                
                {/* Profile Section */}
                <div className="overflow-hidden rounded-lg bg-white shadow dark:bg-gray-800">
                    <div className="px-4 py-5 sm:p-6">
                        <h3 className="text-base font-semibold leading-6 text-gray-900 dark:text-white">Profile Information</h3>
                        
                        {isEditing ? (
                            <form onSubmit={handleUpdateProfile} className="mt-4 space-y-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">Name</label>
                                    <input 
                                        type="text" 
                                        value={profile.name} 
                                        onChange={e => setProfile({...profile, name: e.target.value})}
                                        className="mt-1 block w-full rounded-md border-gray-300 p-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-700" 
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">Image URL</label>
                                    <input 
                                        type="text" 
                                        value={profile.image} 
                                        onChange={e => setProfile({...profile, image: e.target.value})}
                                        className="mt-1 block w-full rounded-md border-gray-300 p-2 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-700" 
                                    />
                                </div>
                                <div className="flex space-x-3">
                                    <button type="submit" className="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500">Save</button>
                                    <button type="button" onClick={() => setIsEditing(false)} className="rounded-md bg-gray-200 px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm hover:bg-gray-300">Cancel</button>
                                </div>
                            </form>
                        ) : (
                            <div className="mt-4">
                                <p className="text-sm text-gray-500 dark:text-gray-400">Email: {user?.email}</p>
                                <p className="text-sm text-gray-500 dark:text-gray-400">Name: {user?.name}</p>
                                <button onClick={() => setIsEditing(true)} className="mt-4 text-indigo-600 hover:text-indigo-500 text-sm font-medium">Edit Profile</button>
                            </div>
                        )}
                        {message && <p className="mt-2 text-sm text-green-600">{message}</p>}
                    </div>
                </div>

                {/* Services Section */}
                <div className="overflow-hidden rounded-lg bg-white shadow dark:bg-gray-800">
                    <div className="px-4 py-5 sm:p-6">
                        <h3 className="text-base font-semibold leading-6 text-gray-900 dark:text-white">My Services</h3>
         
                        <div className="mt-6 flow-root">
                            <ul role="list" className="-my-5 divide-y divide-gray-200 dark:divide-gray-700">
                                {services.map((service) => (
                                    <li key={service.id} className="py-5">
                                        <div className="flex items-center justify-between">
                                            <div>
                                                <h4 className="text-sm font-semibold text-gray-900 dark:text-white">{service.name}</h4>
                                                <p className="text-sm text-gray-500 dark:text-gray-400">{service.description}</p>
                                                {service.enabled && (
                                                    <a href={service.link} target="_blank" className="text-xs text-indigo-600 hover:text-indigo-500">Go to App &rarr;</a>
                                                )}
                                            </div>
                                            <div className="flex items-center">
                                                <button
                                                    onClick={() => toggleService(service.id)}
                                                    className={`${
                                                        service.enabled ? 'bg-indigo-600' : 'bg-gray-200 dark:bg-gray-700'
                                                    } relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2`}
                                                >
                                                    <span
                                                        aria-hidden="true"
                                                        className={`${
                                                            service.enabled ? 'translate-x-5' : 'translate-x-0'
                                                        } pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out`}
                                                    />
                                                </button>
                                            </div>
                                        </div>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>
  );
}
