set -e

dirs=(
  "lib/app"
  "lib/features/prayer_blocks/ui"
  "lib/features/prayer_blocks/view_models"
  "lib/features/consistency/ui"
  "lib/features/consistency/view_models"
  "lib/features/feedback/domain"
  "lib/features/quran_resources/ui"
  "lib/domain/models"
  "lib/data/local"
  "lib/data/repositories"
  "lib/data/services"
  "lib/shared/widgets"
  "test/domain"
  "test/data"
  "test/features"
)

for d in "${dirs[@]}"; do
  mkdir -p "$d"
  # add a .gitkeep so empty folders are tracked by git
  touch "$d/.gitkeep"
done

echo "Folder structure created."