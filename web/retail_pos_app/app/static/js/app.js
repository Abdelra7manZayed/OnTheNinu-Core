function confirmDelete(){return confirm('Are you sure you want to delete this record?');}

document.addEventListener('DOMContentLoaded', function(){
  const sidebar = document.getElementById('appSidebar');
  const backdrop = document.querySelector('[data-sidebar-close]');
  const toggle = document.querySelector('[data-menu-toggle]');
  function openSidebar(){ if(sidebar){ sidebar.classList.add('is-open'); } if(backdrop){ backdrop.classList.add('is-open'); } }
  function closeSidebar(){ if(sidebar){ sidebar.classList.remove('is-open'); } if(backdrop){ backdrop.classList.remove('is-open'); } }
  if(toggle){ toggle.addEventListener('click', function(){ sidebar && sidebar.classList.contains('is-open') ? closeSidebar() : openSidebar(); }); }
  if(backdrop){ backdrop.addEventListener('click', closeSidebar); }
  document.addEventListener('keydown', function(e){ if(e.key === 'Escape'){ closeSidebar(); } });
  document.querySelectorAll('.sidebar .nav-link').forEach(function(link){ link.addEventListener('click', function(){ if(window.innerWidth <= 980){ closeSidebar(); } }); });
  document.querySelectorAll('[data-alert-close]').forEach(function(btn){ btn.addEventListener('click', function(){ const alert = btn.closest('.alert'); if(alert){ alert.remove(); } }); });
});
