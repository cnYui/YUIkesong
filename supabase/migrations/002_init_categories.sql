-- 初始化衣柜分类数据
INSERT INTO public.wardrobe_categories (name, icon, sort_order) VALUES
('上衣', '👔', 1),
('下装', '👖', 2),
('外套', '🧥', 3),
('鞋子', '👟', 4),
('配饰', '👜', 5),
('连衣裙', '👗', 6),
('套装', '🥼', 7)
ON CONFLICT (name) DO NOTHING;