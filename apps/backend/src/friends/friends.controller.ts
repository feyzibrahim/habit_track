import { Controller, Post, Get, Body, Param, Request, UseGuards, Query, BadRequestException } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { FriendsService } from './friends.service';

@Controller('friends')
@UseGuards(JwtAuthGuard)
export class FriendsController {
  constructor(private readonly friendsService: FriendsService) {}

  @Post('request')
  async sendRequest(@Request() req, @Body('email') email: string) {
    return this.friendsService.sendRequest(req.user.id, email);
  }

  @Post('accept/:id')
  async acceptRequest(@Request() req, @Param('id') id: string) {
    return this.friendsService.acceptRequest(req.user.id, id);
  }

  @Post('reject/:id')
  async rejectRequest(@Request() req, @Param('id') id: string) {
    return this.friendsService.rejectRequest(req.user.id, id);
  }

  @Get()
  async getFriends(@Request() req) {
    return this.friendsService.getFriends(req.user.id);
  }

  @Get('requests')
  async getPendingRequests(@Request() req) {
    return this.friendsService.getPendingRequests(req.user.id);
  }

  @Get('leaderboard')
  async getLeaderboard(
    @Request() req,
    @Query('type') type: string = 'friends',
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '20',
  ) {
    const validTypes = ['friends', 'global', 'alltime'];
    if (!validTypes.includes(type)) {
      throw new BadRequestException(
        'Invalid leaderboard type. Use friends, global, or alltime.',
      );
    }
    const pageNum = parseInt(page, 10) || 1;
    const limitNum = parseInt(limit, 10) || 20;
    return this.friendsService.getLeaderboard(
      req.user.id,
      type as 'friends' | 'global' | 'alltime',
      pageNum,
      limitNum,
    );
  }
}
