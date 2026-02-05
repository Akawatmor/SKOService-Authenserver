'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api';
import { useAuthStore } from '@/store/authStore';

export default function AdminDashboard() {
  const router = useRouter();
  const { user, token } = useAuthStore();
  const [activeTab, setActiveTab] = useState('users');
  const [loading, setLoading] = useState(true);

  // Data State
  const [users, setUsers] = useState<any[]>([]);
  const [roles, setRoles] = useState<any[]>([]);
  const [permissions, setPermissions] = useState<any[]>([]);

  // Selection / Editing State
  const [selectedItem, setSelectedItem] = useState<any>(null);
  const [relatedItems, setRelatedItems] = useState<any[]>([]); // User's roles or Role's perms
  const [isModalOpen, setIsModalOpen] = useState(false);

  useEffect(() => {
    if (!token) {
      router.push('/login');
      return;
    }
    // Simple basic protection
    if (user?.email !== process.env.NEXT_PUBLIC_ROOT_EMAIL && user?.email !== 'root@skoservice.com') {
       // In strict mode, we might redirect. For now, let backend handle 403.
    }
    fetchData();
  }, [token, activeTab]);

  const fetchData = async () => {
    setLoading(true);
    try {
      if (activeTab === 'users') {
        const res = await api.get('/admin/users');
        setUsers(res.data);
      } else if (activeTab === 'roles') {
        const res = await api.get('/admin/roles');
        setRoles(res.data);
      } else if (activeTab === 'permissions') {
        const res = await api.get('/admin/permissions');
        setPermissions(res.data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  // --- Handlers ---

  const openEditUser = async (u: any) => {
    setSelectedItem(u);
    // Fetch assigned roles
    try {
        const res = await api.get(`/admin/users/${u.id}/roles`);
        setRelatedItems(res.data); // These are the roles the user HAS
        // Also ensure we have the list of ALL roles to pick from
        if (roles.length === 0) {
            const rRes = await api.get('/admin/roles');
            setRoles(rRes.data);
        }
        setIsModalOpen(true);
    } catch(err) { alert('Failed to fetch details'); }
  };

  const openEditRole = async (r: any) => {
    setSelectedItem(r);
    // Fetch assigned permissions
    try {
        const res = await api.get(`/admin/roles/${r.id}/permissions`);
        setRelatedItems(res.data);
         // Also ensure we have the list of ALL permissions
         if (permissions.length === 0) {
            const pRes = await api.get('/admin/permissions');
            setPermissions(pRes.data);
        }
        setIsModalOpen(true);
    } catch(err) { alert('Failed to fetch details'); }
  };
  
  const saveUserRoles = async (roleIds: number[]) => {
      try {
          await api.post(`/admin/users/${selectedItem.id}/roles`, { role_ids: roleIds });
          setIsModalOpen(false);
          alert('Saved!');
      } catch(e) { alert('Error saving'); }
  };

  const saveRolePerms = async (permIds: number[]) => {
      try {
          await api.post(`/admin/roles/${selectedItem.id}/permissions`, { permission_ids: permIds });
          setIsModalOpen(false);
          alert('Saved!');
      } catch(e) { alert('Error saving'); }
  };

  const createPermission = async (slug: string, desc: string) => {
      try {
          await api.post('/admin/permissions', { slug, description: desc });
          fetchData();
          alert('Created');
      } catch(e) { alert('Error creating'); }
  }

  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <div className="max-w-6xl mx-auto bg-white rounded shadow-md overflow-hidden">
        {/* Header */}
        <div className="bg-red-800 p-6 text-white flex justify-between items-center">
            <h1 className="text-2xl font-bold">Root Admin Dashboard</h1>
            <button onClick={() => router.push('/dashboard')} className="text-sm underline">Back to App</button>
        </div>

        {/* Tabs */}
        <div className="flex border-b">
            {['users', 'roles', 'permissions'].map(tab => (
                <button 
                    key={tab}
                    onClick={() => setActiveTab(tab)}
                    className={`flex-1 p-4 capitalize ${activeTab === tab ? 'bg-gray-50 border-b-2 border-red-800 font-bold' : 'text-gray-500 hover:bg-gray-50'}`}
                >
                    {tab}
                </button>
            ))}
        </div>

        {/* Content */}
        <div className="p-6">
            {loading ? <p>Loading...</p> : (
                <>
                    {activeTab === 'users' && (
                        <UsersTable users={users} onEdit={openEditUser} />
                    )}
                    {activeTab === 'roles' && (
                         <RolesTable roles={roles} onEdit={openEditRole} />
                    )}
                    {activeTab === 'permissions' && (
                        <div>
                            <div className="mb-4 bg-gray-50 p-4 rounded">
                                <h4 className="font-bold text-sm mb-2">Create Permission</h4>
                                <form onSubmit={(e: any) => {
                                    e.preventDefault();
                                    createPermission(e.target.slug.value, e.target.desc.value);
                                    e.target.reset();
                                }} className="flex gap-2">
                                    <input name="slug" placeholder="e.g. system.write" className="border p-2 rounded flex-1" required />
                                    <input name="desc" placeholder="Description" className="border p-2 rounded flex-1" />
                                    <button className="bg-green-600 text-white px-4 py-2 rounded">Add</button>
                                </form>
                            </div>
                            <PermissionsTable perms={permissions} />
                        </div>
                    )}
                </>
            )}
        </div>
      </div>

      {isModalOpen && selectedItem && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4">
              <div className="bg-white rounded max-w-2xl w-full p-6 max-h-[90vh] overflow-auto">
                  <h3 className="text-xl font-bold mb-4">Edit {activeTab === 'users' ? 'User Roles' : 'Role Permissions'}</h3>
                  <div className="mb-4">
                      <p><strong>Target:</strong> {selectedItem.name || selectedItem.slug || selectedItem.email}</p>
                  </div>
                  
                  {activeTab === 'users' && (
                      <RelationManager 
                        all={roles} 
                        current={relatedItems} 
                        idKey="id" 
                        labelKey="name" 
                        onSave={saveUserRoles} 
                        onCancel={() => setIsModalOpen(false)}
                      />
                  )}
                  {activeTab === 'roles' && (
                      <RelationManager 
                        all={permissions} 
                        current={relatedItems} 
                        idKey="id" 
                        labelKey="slug" 
                        onSave={saveRolePerms} 
                        onCancel={() => setIsModalOpen(false)}
                      />
                  )}
              </div>
          </div>
      )}
    </div>
  );
}

function UsersTable({ users, onEdit }: any) {
    return (
        <table className="w-full text-left">
            <thead>
                <tr className="border-b"><th className="p-2">Name</th><th className="p-2">Email</th><th className="p-2">Action</th></tr>
            </thead>
            <tbody>
                {users.map((u: any) => (
                    <tr key={u.id} className="border-b hover:bg-gray-50">
                        <td className="p-2">{u.name}</td>
                        <td className="p-2">{u.email}</td>
                        <td className="p-2"><button onClick={() => onEdit(u)} className="text-blue-600 hover:underline">Manage Roles</button></td>
                    </tr>
                ))}
            </tbody>
        </table>
    )
}

function RolesTable({ roles, onEdit }: any) {
    return (
        <table className="w-full text-left">
            <thead>
                <tr className="border-b"><th className="p-2">Name</th><th className="p-2">Description</th><th className="p-2">Action</th></tr>
            </thead>
            <tbody>
                {roles.map((r: any) => (
                    <tr key={r.id} className="border-b hover:bg-gray-50">
                        <td className="p-2 font-medium">{r.name}</td>
                        <td className="p-2 text-gray-600">{r.description}</td>
                        <td className="p-2"><button onClick={() => onEdit(r)} className="text-blue-600 hover:underline">Manage Perms</button></td>
                    </tr>
                ))}
            </tbody>
        </table>
    )
}

function PermissionsTable({ perms }: any) {
    return (
        <table className="w-full text-left">
            <thead>
                <tr className="border-b"><th className="p-2">Slug</th><th className="p-2">Description</th><th className="p-2">Created</th></tr>
            </thead>
            <tbody>
                {perms.map((p: any) => (
                    <tr key={p.id} className="border-b hover:bg-gray-50">
                        <td className="p-2 font-mono text-sm text-purple-700">{p.slug}</td>
                        <td className="p-2 text-gray-600">{p.description}</td>
                        <td className="p-2 text-xs text-gray-400">{new Date(p.created_at).toLocaleDateString()}</td>
                    </tr>
                ))}
            </tbody>
        </table>
    )
}

function RelationManager({ all, current, idKey, labelKey, onSave, onCancel }: any) {
    // Current is array of objects, we need checks
    const [selectedIds, setSelectedIds] = useState<Set<number>>(new Set(current.map((c: any) => c[idKey])));

    const toggle = (id: number) => {
        const next = new Set(selectedIds);
        if (next.has(id)) next.delete(id);
        else next.add(id);
        setSelectedIds(next);
    }

    return (
        <div>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-2 mb-6 max-h-60 overflow-y-auto border p-2 rounded">
                {all.map((item: any) => (
                    <label key={item[idKey]} className={`flex items-center space-x-2 p-2 rounded border cursor-pointer ${selectedIds.has(item[idKey]) ? 'bg-blue-50 border-blue-200' : 'hover:bg-gray-50'}`}>
                        <input 
                            type="checkbox" 
                            checked={selectedIds.has(item[idKey])} 
                            onChange={() => toggle(item[idKey])}
                            className="rounded text-blue-600"
                        />
                        <span className="text-sm truncate" title={item[labelKey]}>{item[labelKey]}</span>
                    </label>
                ))}
            </div>
            <div className="flex justify-end space-x-2">
                <button onClick={onCancel} className="px-4 py-2 border rounded hover:bg-gray-50">Cancel</button>
                <button onClick={() => onSave(Array.from(selectedIds))} className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">Save Changes</button>
            </div>
        </div>
    )
}
