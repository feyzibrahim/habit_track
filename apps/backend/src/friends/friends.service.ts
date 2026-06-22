import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Friend } from './friend.entity';
import { Goal } from '../goals/goal.entity';
import { XpEvent } from '../xp/xp-event.entity';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';

@Injectable()
export class FriendsService {
  constructor(
    @InjectRepository(Friend)
    private friendRepository: Repository<Friend>,
    @InjectRepository(Goal)
    private goalRepository: Repository<Goal>,
    @InjectRepository(XpEvent)
    private xpEventRepository: Repository<XpEvent>,
    private usersService: UsersService,
  ) {}

  async sendRequest(requesterId: string, recipientEmail: string) {
    if (!recipientEmail) throw new BadRequestException('Email is required');
    
    const recipient = await this.usersService.findByEmail(recipientEmail);
    if (!recipient) throw new NotFoundException('User not found');
    
    if (recipient.id === requesterId) {
      throw new BadRequestException('You cannot send a request to yourself');
    }

    const existing = await this.friendRepository.findOne({
      where: [
        { requester: { id: requesterId }, recipient: { id: recipient.id } },
        { requester: { id: recipient.id }, recipient: { id: requesterId } }
      ]
    });

    if (existing) {
      throw new BadRequestException('Friend request already exists or you are already friends');
    }

    const requester = await this.usersService.findById(requesterId);
    
    const friend = this.friendRepository.create({
      requester,
      recipient,
      status: 'pending',
    });

    return this.friendRepository.save(friend);
  }

  async acceptRequest(userId: string, requestId: string) {
    const request = await this.friendRepository.findOne({
      where: { id: requestId, recipient: { id: userId }, status: 'pending' },
    });

    if (!request) throw new NotFoundException('Request not found or not pending');

    request.status = 'accepted';
    return this.friendRepository.save(request);
  }

  async rejectRequest(userId: string, requestId: string) {
    const request = await this.friendRepository.findOne({
      where: { id: requestId, recipient: { id: userId }, status: 'pending' },
    });

    if (!request) throw new NotFoundException('Request not found or not pending');

    request.status = 'rejected';
    return this.friendRepository.save(request);
  }

  async getFriends(userId: string) {
    // Get all accepted friendships where user is either requester or recipient
    const friendships = await this.friendRepository.find({
      where: [
        { requester: { id: userId }, status: 'accepted' },
        { recipient: { id: userId }, status: 'accepted' }
      ],
      relations: ['requester', 'recipient']
    });

    return friendships.map(f => {
      const friend = f.requester.id === userId ? f.recipient : f.requester;
      return {
        id: friend.id,
        email: friend.email,
        firstName: friend.firstName,
        lastName: friend.lastName,
        friendshipId: f.id
      };
    });
  }

  async getPendingRequests(userId: string) {
    const requests = await this.friendRepository.find({
      where: { recipient: { id: userId }, status: 'pending' },
      relations: ['requester']
    });

    return requests.map(r => ({
      id: r.id,
      requesterId: r.requester.id,
      requesterEmail: r.requester.email,
      requesterFirstName: r.requester.firstName,
      requesterLastName: r.requester.lastName,
      createdAt: r.createdAt
    }));
  }

  private buildActiveMissionsFromRows(
    rows: Array<{
      userId: string;
      id: string;
      title: string;
      durationDays: number;
      status: string;
      progress: string | number;
    }>,
  ) {
    let completedGoals = 0;
    const activeMissions: Array<{
      id: string;
      title: string;
      progress: number;
      durationDays: number;
    }> = [];

    for (const row of rows) {
      if (row.status === 'completed') {
        completedGoals++;
        continue;
      }

      if (row.status !== 'archived') {
        activeMissions.push({
          id: row.id,
          title: row.title,
          progress: Number(row.progress) || 0,
          durationDays: Number(row.durationDays) || 0,
        });
      }
    }

    return { completedGoals, activeMissions };
  }

  private async loadGoalSummariesByUserId(userIds: string[]) {
    if (userIds.length === 0) return new Map();

    const rows = await this.goalRepository.manager.query<
      Array<{
        userId: string;
        id: string;
        title: string;
        durationDays: number;
        status: string;
        progress: string;
      }>
    >(
      `
        SELECT
          g."userId" AS "userId",
          g.id AS id,
          g.title AS title,
          g."durationDays" AS "durationDays",
          g.status AS status,
          CASE
            WHEN COUNT(ai.id) = 0 THEN 0
            ELSE COUNT(CASE WHEN ai."isCompleted" = true THEN 1 END)::float / COUNT(ai.id)
          END AS progress
        FROM goal g
        LEFT JOIN milestone m ON m."goalId" = g.id
        LEFT JOIN action_item ai ON ai."milestoneId" = m.id
        WHERE g."userId" = ANY($1)
        GROUP BY g.id, g."userId", g.title, g."durationDays", g.status
      `,
      [userIds],
    );

    const goalsByUserId = new Map<
      string,
      Array<{
        userId: string;
        id: string;
        title: string;
        durationDays: number;
        status: string;
        progress: string;
      }>
    >();

    for (const row of rows) {
      const existing = goalsByUserId.get(row.userId) ?? [];
      existing.push(row);
      goalsByUserId.set(row.userId, existing);
    }

    return goalsByUserId;
  }

  private async loadLegacyScores(userIds: string[]) {
    if (userIds.length === 0) return new Map<string, number>();

    const rows = await this.goalRepository.manager.query<
      Array<{ userId: string; score: string }>
    >(
      `
        SELECT
          g."userId" AS "userId",
          COALESCE(
            SUM(
              CASE WHEN ai."isCompleted" = true THEN 10 ELSE 0 END
            ) + SUM(
              CASE WHEN ai.type = 'habit' THEN ai."completedCount" * 2 ELSE 0 END
            ),
            0
          ) AS score
        FROM goal g
        LEFT JOIN milestone m ON m."goalId" = g.id
        LEFT JOIN action_item ai ON ai."milestoneId" = m.id
        WHERE g."userId" = ANY($1)
        GROUP BY g."userId"
      `,
      [userIds],
    );

    return new Map(rows.map(row => [row.userId, Number(row.score) || 0]));
  }

  private mapUserEntry(
    user: User,
    score: number,
    goalRows: Array<{
      userId: string;
      id: string;
      title: string;
      durationDays: number;
      status: string;
      progress: string | number;
    }> = [],
  ) {
    const { completedGoals, activeMissions } =
      this.buildActiveMissionsFromRows(goalRows);

    return {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      score,
      completedGoals,
      activeMissions,
      isGuest: user.isGuest,
    };
  }

  async getLeaderboard(
    userId: string,
    type: 'friends' | 'global' | 'alltime',
    page: number = 1,
    limit: number = 20,
  ) {
    const offset = (page - 1) * limit;
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const usersRepo = this.usersService['usersRepository'] as Repository<User>;

    let scoreSelect: string;
    let parameters: any = { userId };

    if (type === 'alltime') {
      scoreSelect = `(
        COALESCE((SELECT SUM(xp.xp) FROM xp_event xp WHERE xp."userId" = user.id), 0) +
        COALESCE((
          SELECT SUM(CASE WHEN ai."isCompleted" = true THEN 10 ELSE 0 END) + SUM(CASE WHEN ai.type = 'habit' THEN ai."completedCount" * 2 ELSE 0 END)
          FROM goal g
          LEFT JOIN milestone m ON m."goalId" = g.id
          LEFT JOIN action_item ai ON ai."milestoneId" = m.id
          WHERE g."userId" = "user"."id"
        ), 0)
      )`;
    } else {
      parameters.sevenDaysAgo = sevenDaysAgo;
      scoreSelect = `COALESCE((
        SELECT SUM(xp.xp)
        FROM xp_event xp
        WHERE xp."userId" = user.id AND xp."createdAt" >= :sevenDaysAgo
      ), 0)`;
    }

    const query = usersRepo.createQueryBuilder('user')
      .select([
        'user.id AS id',
        'user.email AS email',
        'user.firstName AS "firstName"',
        'user.lastName AS "lastName"',
        'user.isGuest AS "isGuest"'
      ])
      .addSelect(scoreSelect, 'score')
      .where('((user.isGuest = false OR user.id = :userId) AND user.email IS NOT NULL)', { userId })
      .orderBy('score', 'DESC')
      .limit(limit)
      .offset(offset);

    if (type === 'friends') {
      const friends = await this.getFriends(userId);
      const friendIds = new Set(friends.map(f => f.id));
      friendIds.add(userId);
      query.andWhere('user.id IN (:...friendIds)', { friendIds: [...friendIds] });
    }

    const rawResults = await query.setParameters(parameters).getRawMany();
    const resultUserIds = rawResults.map(r => r.id);
    const goalsByUserId = await this.loadGoalSummariesByUserId(resultUserIds);

    return rawResults.map(row => {
      const user = new User();
      user.id = row.id;
      user.email = row.email;
      user.firstName = row.firstName;
      user.lastName = row.lastName;
      user.isGuest = row.isGuest;
      const score = Number(row.score) || 0;
      return this.mapUserEntry(user, score, goalsByUserId.get(user.id) ?? []);
    });
  }
}
