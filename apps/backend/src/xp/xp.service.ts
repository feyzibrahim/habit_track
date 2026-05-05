import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { XpEvent } from './xp-event.entity';
import { User } from '../users/user.entity';

@Injectable()
export class XpService {
  private readonly logger = new Logger(XpService.name);

  constructor(
    @InjectRepository(XpEvent)
    private xpRepository: Repository<XpEvent>,
  ) {}

  async addXpEvent(user: User, title: string, subtitle: string, xp: number): Promise<XpEvent> {
    this.logger.log(`Adding ${xp} XP for user ${user.id} - ${title}`);
    const event = this.xpRepository.create({
      user,
      title,
      subtitle,
      xp,
    });
    return this.xpRepository.save(event);
  }

  async getXpHistory(userId: string): Promise<XpEvent[]> {
    return this.xpRepository.find({
      where: { user: { id: userId } },
      order: { createdAt: 'DESC' },
    });
  }
}
