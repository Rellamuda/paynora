'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function DashboardRedirect() {
  const router = useRouter();

  useEffect(() => {
    // PayNora is Mobile-Only for security (no financial transactions or dashboard on web)
    router.replace('/');
  }, [router]);

  return null;
}
