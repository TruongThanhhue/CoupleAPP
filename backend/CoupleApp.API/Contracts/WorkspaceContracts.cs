namespace CoupleApp.API.Contracts;

public sealed record SaveTaskRequest(string? Title, string? Notes, bool IsComplete,
    bool IsShared, string? Priority, DateTimeOffset? DueAt);
public sealed record TaskResponse(Guid Id, string Title, string? Notes, bool IsComplete,
    bool IsShared, string Priority, DateTimeOffset? DueAt, DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt, bool CreatedByMe);

public sealed record SaveEventRequest(string? Title, string? Notes, string? Location,
    DateTimeOffset StartsAt, DateTimeOffset EndsAt, bool IsShared);
public sealed record EventResponse(Guid Id, string Title, string? Notes, string? Location,
    DateTimeOffset StartsAt, DateTimeOffset EndsAt, bool IsShared,
    DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt, bool CreatedByMe);

public static class WorkspaceValidation
{
    public static Dictionary<string, string[]> Validate(SaveTaskRequest request)
    {
        var errors = ValidateText(request.Title, request.Notes);
        if (request.Priority is not ("low" or "normal" or "high"))
            errors["priority"] = ["Mức ưu tiên không hợp lệ."];
        if (request.DueAt is { } due && !ValidDate(due))
            errors["dueAt"] = ["Hạn hoàn thành phải nằm trong khoảng năm 2000 đến 2100."];
        return errors;
    }

    public static Dictionary<string, string[]> Validate(SaveEventRequest request)
    {
        var errors = ValidateText(request.Title, request.Notes);
        if (request.Location?.Length > 300) errors["location"] = ["Địa điểm tối đa 300 ký tự."];
        if (!ValidDate(request.StartsAt)) errors["startsAt"] = ["Thời gian bắt đầu phải nằm trong khoảng năm 2000 đến 2100."];
        if (!ValidDate(request.EndsAt) || request.EndsAt <= request.StartsAt)
            errors["endsAt"] = ["Thời gian kết thúc phải sau thời gian bắt đầu và không quá năm 2100."];
        return errors;
    }

    private static bool ValidDate(DateTimeOffset value) => value.Year is >= 2000 and <= 2100;

    private static Dictionary<string, string[]> ValidateText(string? title, string? notes)
    {
        var errors = new Dictionary<string, string[]>();
        if (string.IsNullOrWhiteSpace(title) || title.Trim().Length > 200)
            errors["title"] = ["Tiêu đề cần từ 1 đến 200 ký tự."];
        if (notes?.Length > 2000) errors["notes"] = ["Ghi chú tối đa 2000 ký tự."];
        return errors;
    }
}
