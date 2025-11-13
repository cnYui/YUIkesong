create table if not exists public.profiles (
  id uuid primary key,
  nickname text,
  avatar_url text,
  city text,
  created_at timestamp default now()
);

create table if not exists public.selfies (
  id uuid primary key,
  user_id uuid not null,
  image_path text not null,
  is_default boolean default false,
  created_at timestamp default now()
);

create index if not exists idx_selfies_user_default on public.selfies(user_id, is_default);

create table if not exists public.wardrobe_categories (
  id serial primary key,
  name text unique not null,
  icon text,
  sort_order int default 0
);

create table if not exists public.wardrobe_items (
  id uuid primary key,
  user_id uuid not null,
  category_id int references public.wardrobe_categories(id),
  image_path text not null,
  color text,
  season text,
  metadata jsonb,
  created_at timestamp default now(),
  updated_at timestamp default now(),
  deleted_at timestamp
);

create index if not exists idx_wardrobe_user_cat on public.wardrobe_items(user_id, category_id);
create index if not exists idx_wardrobe_user_created on public.wardrobe_items(user_id, created_at);

create table if not exists public.recommendations (
  id uuid primary key,
  user_id uuid,
  weather_tag text,
  title text not null,
  description text,
  source text check (source in ('ai','manual')) default 'ai',
  created_at timestamp default now()
);

create index if not exists idx_reco_user_created on public.recommendations(user_id, created_at);

create table if not exists public.recommendation_items (
  recommendation_id uuid not null,
  wardrobe_item_id uuid not null,
  slot text,
  primary key (recommendation_id, wardrobe_item_id)
);

create table if not exists public.ai_tasks (
  id uuid primary key,
  user_id uuid not null,
  task_type text check (task_type in ('image','video')) not null,
  status text check (status in ('pending','processing','finished','failed')) default 'pending',
  input_payload jsonb,
  result_url text,
  created_at timestamp default now(),
  updated_at timestamp default now()
);

create index if not exists idx_ai_user_status on public.ai_tasks(user_id, status);
create index if not exists idx_ai_created on public.ai_tasks(created_at);

create table if not exists public.saved_looks (
  id uuid primary key,
  user_id uuid not null,
  ai_task_id uuid,
  recommendation_id uuid,
  cover_image_url text not null,
  created_at timestamp default now()
);

create index if not exists idx_looks_user_created on public.saved_looks(user_id, created_at);

create table if not exists public.saved_look_items (
  saved_look_id uuid not null,
  wardrobe_item_id uuid not null,
  slot text,
  primary key (saved_look_id, wardrobe_item_id)
);

create table if not exists public.community_posts (
  id uuid primary key,
  user_id uuid not null,
  cover_image_url text,
  description text,
  visibility text check (visibility in ('public','private')) default 'public',
  created_at timestamp default now(),
  updated_at timestamp default now(),
  deleted_at timestamp
);

create index if not exists idx_posts_user_created on public.community_posts(user_id, created_at);
create index if not exists idx_posts_vis_created on public.community_posts(visibility, created_at);

create table if not exists public.community_post_images (
  id uuid primary key,
  post_id uuid not null,
  image_url text not null,
  sort_order int
);

create index if not exists idx_post_images_post on public.community_post_images(post_id);

create table if not exists public.community_likes (
  post_id uuid not null,
  user_id uuid not null,
  created_at timestamp default now(),
  primary key (post_id, user_id)
);

create table if not exists public.community_comments (
  id uuid primary key,
  post_id uuid not null,
  user_id uuid not null,
  content text not null,
  parent_id uuid,
  created_at timestamp default now()
);

create index if not exists idx_comments_post_created on public.community_comments(post_id, created_at);
create index if not exists idx_comments_parent on public.community_comments(parent_id);

create table if not exists public.follows (
  follower_id uuid not null,
  followee_id uuid not null,
  created_at timestamp default now(),
  primary key (follower_id, followee_id)
);