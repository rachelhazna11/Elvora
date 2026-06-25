import { supabase } from './supabase.js';

(async () => {
  const { data: { user } } = await supabase.auth.getUser();
  if (user?.app_metadata?.role === 'admin') {
    window.location.replace('/admin.html');
  }
})();
