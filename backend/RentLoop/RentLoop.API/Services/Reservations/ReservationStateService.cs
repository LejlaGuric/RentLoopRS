using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.Helpers;
using RentLoop.API.Models;

namespace RentLoop.API.Services.Reservations
{
    public class ReservationStateService : IReservationStateService
    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<ReservationStateService> _logger;

        public ReservationStateService(
            ApplicationDbContext db,
            ILogger<ReservationStateService> logger)
        {
            _db = db;
            _logger = logger;
        }

        public bool CanTransition(int currentStatusId, int newStatusId)
        {
            var allowed = currentStatusId switch
            {
                ReservationStatusIds.Pending =>
                    newStatusId == ReservationStatusIds.Approved ||
                    newStatusId == ReservationStatusIds.Rejected ||
                    newStatusId == ReservationStatusIds.Cancelled,

                ReservationStatusIds.Approved =>
                    newStatusId == ReservationStatusIds.Cancelled,

                ReservationStatusIds.Rejected => false,
                ReservationStatusIds.Cancelled => false,

                _ => false
            };

            if (!allowed)
            {
                _logger.LogWarning(
                    "Invalid reservation state transition attempted: {CurrentStatus} -> {NewStatus}",
                    ReservationStatusNames.GetName(currentStatusId),
                    ReservationStatusNames.GetName(newStatusId));
            }

            return allowed;
        }

        public async Task<ReservationStateChangeResult> ChangeStatusAsync(Reservation reservation, int newStatusId)
        {
            if (reservation == null)
            {
                _logger.LogWarning("Reservation state change attempted but reservation was null.");
                return ReservationStateChangeResult.Fail("Reservation not found.");
            }

            var currentStatusId = reservation.StatusId;

            _logger.LogInformation(
                "Reservation state change attempt. ReservationId: {ReservationId}, CurrentStatus: {CurrentStatus}, TargetStatus: {NewStatus}",
                reservation.Id,
                ReservationStatusNames.GetName(currentStatusId),
                ReservationStatusNames.GetName(newStatusId));

            if (currentStatusId == newStatusId)
            {
                _logger.LogWarning(
                    "Reservation {ReservationId} already in status {Status}.",
                    reservation.Id,
                    ReservationStatusNames.GetName(currentStatusId));

                return ReservationStateChangeResult.Fail("Reservation is already in that status.");
            }

            var statusExists = await _db.ReservationStatuses.AnyAsync(x => x.Id == newStatusId);
            if (!statusExists)
            {
                _logger.LogWarning(
                    "Reservation {ReservationId} attempted transition to non-existing status {StatusId}.",
                    reservation.Id,
                    newStatusId);

                return ReservationStateChangeResult.Fail("Target reservation status does not exist.");
            }

            if (!CanTransition(currentStatusId, newStatusId))
            {
                _logger.LogWarning(
                    "Reservation {ReservationId} transition not allowed: {CurrentStatus} -> {NewStatus}",
                    reservation.Id,
                    ReservationStatusNames.GetName(currentStatusId),
                    ReservationStatusNames.GetName(newStatusId));

                return ReservationStateChangeResult.Fail(
                    $"Transition from '{ReservationStatusNames.GetName(currentStatusId)}' to '{ReservationStatusNames.GetName(newStatusId)}' is not allowed."
                );
            }

            reservation.StatusId = newStatusId;

            _logger.LogInformation(
                "Reservation {ReservationId} status successfully changed to {NewStatus}.",
                reservation.Id,
                ReservationStatusNames.GetName(newStatusId));

            return ReservationStateChangeResult.Ok(
                $"Reservation status changed to '{ReservationStatusNames.GetName(newStatusId)}'."
            );
        }
    }
}