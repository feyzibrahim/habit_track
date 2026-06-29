import { Injectable, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WaitlistUser } from './waitlist-user.entity';

@Injectable()
export class WaitlistService {
  constructor(
    @InjectRepository(WaitlistUser)
    private waitlistRepository: Repository<WaitlistUser>,
  ) {}

  async joinWaitlist(email: string): Promise<WaitlistUser> {
    try {
      const existingUser = await this.waitlistRepository.findOne({ where: { email } });
      if (existingUser) {
        return existingUser; // If they already joined, just return success
      }
      const user = this.waitlistRepository.create({ email });
      return await this.waitlistRepository.save(user);
    } catch (error) {
      if (error.code === '23505') { // unique violation
        throw new ConflictException('Email already on waitlist');
      }
      throw error;
    }
  }
}
