'use client';

import { useEffect, useRef } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import api from '@/lib/api';
import { useAuthStore } from '@/store/authStore';

export default function GoogleCallback() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const setAuth = useAuthStore((state) => state.setAuth);
  const processedRef = useRef(false);

  useEffect(() => {
    const code = searchParams.get('code');
    const error = searchParams.get('error');

    if (error) {
      router.push(`/login?error=${error}`);
      return;
    }

    if (!code) {
      router.push('/login?error=no_code');
      return;
    }

    if (processedRef.current) return;
    processedRef.current = true;

    const exchangeCode = async () => {
      try {
        const res = await api.post('/auth/oauth/google/callback', { code });
        setAuth(res.data.user, res.data.access_token);
        router.push('/dashboard');
      } catch (err: any) {
        console.error('Google login failed:', err);
        const params = new URLSearchParams();
        params.set('error', err.response?.data?.message || 'Google login failed');
        router.push(`/login?${params.toString()}`);
      }
    };

    exchangeCode();
  }, [searchParams, router, setAuth]);

  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="text-center">
        <h2 className="text-xl font-semibold mb-2">Authenticating with Google...</h2>
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600 mx-auto"></div>
      </div>
    </div>
  );
}
