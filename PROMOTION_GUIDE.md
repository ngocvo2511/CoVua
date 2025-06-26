# Hướng dẫn xử lý phong cấp cho tốt

## Vấn đề ban đầu
Khi quân tốt đến ô phong cấp, Prolog yêu cầu người dùng nhập lựa chọn phong cấp qua console (`get_promotion_choice`), nhưng trong giao diện WPF, cần hiển thị menu để người dùng chọn.

## Giải pháp đã triển khai

### 1. Sửa đổi Prolog (movement.pl)
- Thêm predicate `get_promotion_choice(PromotionPiece, PieceType)` để nhận tham số thay vì yêu cầu input từ console
- Thêm predicate `simulate_move_with_promotion(From, To, Color, Position, PromotionPiece, NewPosition)` để xử lý phong cấp với tham số

### 2. Sửa đổi Prolog (chess.pl)
- Sửa predicate `place_piece(From, To, Status)` để kiểm tra phong cấp và throw exception khi cần
- Thêm predicate `place_piece_with_promotion(From, To, PromotionPiece, Status)` để xử lý nước đi phong cấp

### 3. Sửa đổi C# (PrologEngine.cs)
- Cập nhật method `MakeMove` để bắt exception phong cấp từ Prolog
- Thêm method `MakeMoveWithPromotion(int fromPos, int toPos, string promotionPiece, out string status)` để gọi predicate mới

### 4. Sửa đổi C# (GameUserControl.xaml.cs)
- Cập nhật `OnToPositionSelected` để sử dụng logic kiểm tra phong cấp từ Prolog
- Cập nhật `HandlePromotion` để sử dụng `PrologEngine.MakeMoveWithPromotion`

## Cách hoạt động

1. **Khi người dùng chọn nước đi:**
   - `OnToPositionSelected` gọi `PrologEngine.MakeMove`
   - Prolog kiểm tra xem có phải là nước đi phong cấp không
   - Nếu là phong cấp, Prolog throw exception `promotion_required`
   - C# bắt exception và set `needsPromotion = true`

2. **Khi cần phong cấp:**
   - C# gọi `HandlePromotion` để hiển thị menu phong cấp
   - Người dùng chọn quân cờ phong cấp

3. **Khi người dùng chọn quân cờ phong cấp:**
   - `HandlePromotion` chuyển đổi lựa chọn thành ký tự Prolog (q/r/b/k)
   - Gọi `PrologEngine.MakeMoveWithPromotion` với tham số phong cấp
   - Cập nhật giao diện và kiểm tra trạng thái ván cờ

4. **Xử lý trong Prolog:**
   - `place_piece_with_promotion` gọi `simulate_move_with_promotion`
   - `simulate_move_with_promotion` sử dụng `get_promotion_choice(PromotionPiece, PieceType)` để xử lý phong cấp
   - Cập nhật bàn cờ với quân cờ mới

## Các thay đổi chính

### Prolog (chess.pl)
```prolog
place_piece(From, To, Status) :-
    % Check if this is a pawn promotion move
    (find_piece_type(From, pawn, Position, Color), is_promotion_move(From, To, Color, Position)) ->
        % This is a promotion move, but we need the promotion piece choice
        throw(error(promotion_required, context(place_piece, 'Pawn promotion requires piece choice')))
    ;
        % Normal move processing
        % ...
```

### C# (PrologEngine.cs)
```csharp
public static bool MakeMove(int fromPos, int toPos, out string status, out bool needsPromotion)
{
    // ...
    catch (PlException ex)
    {
        // Kiểm tra xem có phải là lỗi phong cấp không
        if (ex.Message.Contains("promotion_required"))
        {
            needsPromotion = true;
            return false;
        }
    }
    // ...
}
```

### C# (GameUserControl.xaml.cs)
```csharp
// Thực hiện nước đi trong Prolog
if (PrologEngine.MakeMove(fromPos, toPos, out var status, out var needsPromotion))
{
    // Xử lý nước đi bình thường
}
else if (needsPromotion)
{
    // Prolog đã xác định đây là nước đi phong cấp, gọi UI phong cấp
    HandlePromotion(move.FromPos, move.ToPos);
}
```

## Lợi ích
- **Logic cờ vua hoàn toàn ở Prolog** - kiểm tra phong cấp được thực hiện ở Prolog
- **Tách biệt trách nhiệm** - Prolog xử lý logic, C# xử lý giao diện
- **Không còn yêu cầu input từ console** - hoàn toàn tích hợp với giao diện WPF
- **Giao diện người dùng thân thiện** - menu phong cấp trực quan
- **Duy trì tính nhất quán** của logic cờ vua 