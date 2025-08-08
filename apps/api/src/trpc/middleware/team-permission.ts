import type { Session } from "@api/utils/auth";
import { teamCache } from "@midday/cache/team-cache";
import type { Database } from "@midday/db/client";
import { TRPCError } from "@trpc/server";

export const withTeamPermission = async <TReturn>(opts: {
  ctx: {
    session?: Session | null;
    db: Database;
  };
  next: (opts: {
    ctx: {
      session?: Session | null;
      db: Database;
      teamId: string | null;
    };
  }) => Promise<TReturn>;
}) => {
  const { ctx, next } = opts;

  const userId = ctx.session?.user?.id;

  if (!userId) {
    throw new TRPCError({
      code: "UNAUTHORIZED",
      message: "User not authenticated",
    });
  }

  const result = await ctx.db.query.users.findFirst({
    with: {
      usersOnTeams: {
        columns: {
          id: true,
          teamId: true,
        },
      },
    },
    where: (users, { eq }) => eq(users.id, userId),
  });

  // If user doesn't exist in public.users yet, they're likely just registered
  // Allow them through with null teamId so they can complete setup
  if (!result) {
    return next({
      ctx: {
        session: ctx.session,
        teamId: null,
        db: ctx.db,
      },
    });
  }

  const teamId = result.teamId;

  // If teamId is null, user has no team assigned but this is now allowed
  if (teamId !== null) {
    const cacheKey = `user:${userId}:team:${teamId}`;
    let hasAccess = teamCache.get(cacheKey);

    if (hasAccess === undefined) {
      hasAccess = result.usersOnTeams.some(
        (membership) => membership.teamId === teamId,
      );

      teamCache.set(cacheKey, hasAccess);
    }

    if (!hasAccess) {
      throw new TRPCError({
        code: "FORBIDDEN",
        message: "No permission to access this team 2",
      });
    }
  }

  return next({
    ctx: {
      session: ctx.session,
      teamId,
      db: ctx.db,
    },
  });
};
