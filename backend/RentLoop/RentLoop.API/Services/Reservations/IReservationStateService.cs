using RentLoop.API.Models;

namespace RentLoop.API.Services.Reservations
{
    public interface IReservationStateService
    {
        Task<ReservationStateChangeResult> ChangeStatusAsync(Reservation reservation, int newStatusId);
        bool CanTransition(int currentStatusId, int newStatusId);
    }
}