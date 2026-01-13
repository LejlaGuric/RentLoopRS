namespace RentLoop.API.DTOs.Listing
{
    public class ListingImageCreateRequest
    {
        public string Url { get; set; } = string.Empty;
        public bool IsCover { get; set; } = false;
        public int SortOrder { get; set; } = 0;
    }
}
