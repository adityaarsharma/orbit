#!/usr/bin/env bash
# Orbit — Seed large dataset for scale testing
#
# Generates production-scale fixtures so the gauntlet actually exercises the
# plugin at realistic data volumes. Plugins that work with 5 posts often
# fail with 10,000 (WP_Query posts_per_page => -1, get_all_meta patterns).
#
# Usage:
#   bash scripts/seed-large-dataset.sh [POSTS] [USERS] [TERMS]
# Defaults: 1000 posts, 500 users, 100 terms

set -e

POSTS="${1:-1000}"
USERS="${2:-500}"
TERMS="${3:-100}"
WP_ENV_RUN="${WP_ENV_RUN:-npx wp-env run cli wp}"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

wp() { $WP_ENV_RUN "$@"; }

echo -e "${CYAN}Seeding large dataset: ${POSTS} posts, ${USERS} users, ${TERMS} terms${NC}"
echo "This may take 5-10 minutes..."

# Check current state — skip if already seeded
CURRENT_POSTS=$(wp post list --post_status=publish --format=count 2>/dev/null || echo 0)
if [ "$CURRENT_POSTS" -ge "$POSTS" ]; then
  echo -e "${GREEN}✓ Already have $CURRENT_POSTS posts — skipping seed${NC}"
  exit 0
fi

# 1. Create terms first (so posts can be assigned)
echo "Creating $TERMS categories..."
for i in $(seq 1 $TERMS); do
  wp term create category "Category $i" --description="Auto-generated #$i" --porcelain 2>/dev/null >/dev/null || true
done

# 2. Create users
echo "Creating $USERS users..."
for i in $(seq 1 $USERS); do
  wp user create "orbit_user_$i" "orbit_u${i}@test.local" --role=subscriber --porcelain 2>/dev/null >/dev/null || true
done

# 3. Generate posts in batches via WP-CLI eval (much faster than one-by-one)
echo "Generating $POSTS posts in batches of 100..."
BATCH_SIZE=100
BATCHES=$(( (POSTS + BATCH_SIZE - 1) / BATCH_SIZE ))

for batch in $(seq 1 $BATCHES); do
  START=$(( (batch - 1) * BATCH_SIZE + 1 ))
  END=$(( batch * BATCH_SIZE ))
  [ "$END" -gt "$POSTS" ] && END=$POSTS
  COUNT=$(( END - START + 1 ))

  wp eval "
    for (\$i = $START; \$i <= $END; \$i++) {
      \$post_id = wp_insert_post([
        'post_title'   => 'Orbit Test Post ' . \$i,
        'post_content' => 'Auto-generated content for scale testing. ' . str_repeat('Lorem ipsum dolor sit amet. ', 20),
        'post_status'  => 'publish',
        'post_type'    => 'post',
        'post_author'  => rand(1, min(10, $USERS)),
      ]);
      if (\$post_id) {
        // Add random meta (exercises post meta patterns)
        update_post_meta(\$post_id, '_orbit_test_data', ['key' => 'value_' . \$i]);
        update_post_meta(\$post_id, '_orbit_test_number', rand(1, 1000));
      }
    }
  " 2>/dev/null

  echo "  Batch $batch / $BATCHES — posts $START-$END"
done

# 4. Summary
FINAL_POSTS=$(wp post list --post_status=publish --format=count)
FINAL_USERS=$(wp user list --format=count)
FINAL_TERMS=$(wp term list category --format=count)
FINAL_META=$(wp db query "SELECT COUNT(*) FROM wp_postmeta" --skip-column-names 2>/dev/null)

echo ""
echo -e "${GREEN}✓ Dataset seeded:${NC}"
echo "  Posts: $FINAL_POSTS"
echo "  Users: $FINAL_USERS"
echo "  Terms: $FINAL_TERMS"
echo "  Post meta rows: $FINAL_META"
echo ""
echo "Now run: bash scripts/gauntlet.sh --plugin <path>"
echo "Expect slower queries — that's the point. Watch for timeouts."
