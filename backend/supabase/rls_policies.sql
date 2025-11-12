alter table public.selfies enable row level security;
alter table public.wardrobe_items enable row level security;
alter table public.recommendations enable row level security;
alter table public.recommendation_items enable row level security;
alter table public.ai_tasks enable row level security;
alter table public.saved_looks enable row level security;
alter table public.saved_look_items enable row level security;
alter table public.community_posts enable row level security;
alter table public.community_post_images enable row level security;
alter table public.community_likes enable row level security;
alter table public.community_comments enable row level security;
alter table public.follows enable row level security;
alter table public.profiles enable row level security;

create policy profiles_owner_select on public.profiles for select using (id = auth.uid());
create policy profiles_owner_write on public.profiles for all using (id = auth.uid()) with check (id = auth.uid());

create policy selfies_owner_select on public.selfies for select using (user_id = auth.uid());
create policy selfies_owner_write on public.selfies for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy wardrobe_owner_select on public.wardrobe_items for select using (user_id = auth.uid());
create policy wardrobe_owner_write on public.wardrobe_items for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy reco_owner_select on public.recommendations for select using (user_id = auth.uid());
create policy reco_owner_write on public.recommendations for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy reco_items_owner_select on public.recommendation_items for select using (
  exists(select 1 from public.recommendations r where r.id = recommendation_id and r.user_id = auth.uid())
);
create policy reco_items_owner_write on public.recommendation_items for all using (
  exists(select 1 from public.recommendations r where r.id = recommendation_id and r.user_id = auth.uid())
) with check (
  exists(select 1 from public.recommendations r where r.id = recommendation_id and r.user_id = auth.uid())
);

create policy ai_owner_select on public.ai_tasks for select using (user_id = auth.uid());
create policy ai_owner_write on public.ai_tasks for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy looks_owner_select on public.saved_looks for select using (user_id = auth.uid());
create policy looks_owner_write on public.saved_looks for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy look_items_owner_select on public.saved_look_items for select using (
  exists(select 1 from public.saved_looks s where s.id = saved_look_id and s.user_id = auth.uid())
);
create policy look_items_owner_write on public.saved_look_items for all using (
  exists(select 1 from public.saved_looks s where s.id = saved_look_id and s.user_id = auth.uid())
) with check (
  exists(select 1 from public.saved_looks s where s.id = saved_look_id and s.user_id = auth.uid())
);

create policy posts_public_select on public.community_posts for select using (visibility = 'public' or user_id = auth.uid());
create policy posts_owner_write on public.community_posts for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy post_images_public_select on public.community_post_images for select using (
  exists(select 1 from public.community_posts p where p.id = post_id and (p.visibility = 'public' or p.user_id = auth.uid()))
);
create policy post_images_owner_write on public.community_post_images for all using (
  exists(select 1 from public.community_posts p where p.id = post_id and p.user_id = auth.uid())
) with check (
  exists(select 1 from public.community_posts p where p.id = post_id and p.user_id = auth.uid())
);

create policy likes_public_select on public.community_likes for select using (true);
create policy likes_user_write on public.community_likes for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy comments_public_select on public.community_comments for select using (true);
create policy comments_user_write on public.community_comments for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy follows_public_select on public.follows for select using (true);
create policy follows_user_write on public.follows for all using (follower_id = auth.uid()) with check (follower_id = auth.uid());
